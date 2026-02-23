const { setGlobalOptions } = require("firebase-functions");
const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const axios = require("axios");
require("dotenv").config();
const admin = require("firebase-admin");
const { PubSub } = require('@google-cloud/pubsub');

admin.initializeApp();
const webhookHandler = require("./webhookHandler");
const Busboy = require("busboy");
setGlobalOptions({ maxInstances: 10 });

const FormData = require("form-data");
const WABA_ID = process.env.WABA_ID;
const PHONENUMBERID = process.env.PHONENUMBERID;
const TOKEN = process.env.INTERAKT_TOKEN;
const BASE_URL = `https://amped-express.interakt.ai/api/v24.0/${WABA_ID}/message_templates`;
const SEND_MESSAGE_URL = `https://amped-express.interakt.ai/api/v24.0/${PHONENUMBERID}/messages`;
const UPLOAD_URL = `https://amped-express.interakt.ai/api/v24.0/${PHONENUMBERID}/media_handle`;
const UPLOAD_BROADCAST_MEDIA = `https://amped-express.interakt.ai/api/v24.0/${PHONENUMBERID}/media`;
const db = admin.firestore();
const pubSubClient = new PubSub();


// ============================================================
// 🚀 SEND WHATSAPP MESSAGE (TEXT, IMAGE, DOCUMENT) - WITH STATS
// ============================================================
const sendWhatsAppMessage = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");
  if (req.method === "OPTIONS") return res.status(200).end();

  try {
    const response = await sendWhatsAppMessageHelper(req.body);

    return res.status(response.statusCode).json({
      success: response.success,
      data: response.data,
      message: response.message,
    });

  } catch (err) {
    const errData = err.response?.data ?? err.message;

    return res.status(500).json({
      success: false,
      message: errData,
    });
  }
});

async function sendWhatsAppMessageHelper(requestBody) {

  try {
    const { phoneNumber, message, chatId, messageType, mediaUrl, fileName, caption } = requestBody;

    if (!phoneNumber || (!message && !mediaUrl)) {
      return {
        success: false,
        message: "Phone number and message/media are required",
      };
    }

    const formattedPhone = phoneNumber.replace(/[+\s-]/g, "");

    let payload = {
      messaging_product: "whatsapp",
      to: formattedPhone,
    };

    let messageContent = message;
    let mediaType = messageType || "text";

    if (mediaType === "text") {
      payload.type = "text";
      payload.text = { body: message };
    } else if (mediaType === "image") {
      payload.type = "image";
      payload.image = { link: mediaUrl };
      if (caption) payload.image.caption = caption;
      messageContent = caption || "📷 Image";
    } else if (mediaType === "document") {
      payload.type = "document";
      payload.document = {
        link: mediaUrl,
        filename: fileName || "document.pdf",
      };
      if (caption) payload.document.caption = caption;
      messageContent = caption || `📄 ${fileName || "Document"}`;
    }

    logger.info("Sending WhatsApp message:", payload);

    const response = await axios.post(SEND_MESSAGE_URL, payload, {
      headers: {
        "x-access-token": TOKEN,
        "x-waba-id": WABA_ID,
        "Content-Type": "application/json",
      },
    });

    const whatsappMessageId = response.data?.messages?.[0]?.id;

    // 📊 NEW: Increment sent count
    const today = new Date().toISOString().split("T")[0];
    await incrementDailyStats(today, "sent");
    logger.info(`📊 Incremented sent count for ${today}`);

    // Store message in Firestore
    if (chatId) {
      const messageRef = db
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc();

      await messageRef.set({
        content: messageContent,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isFromMe: true,
        senderName: "Admin",
        senderAvatar: null,
        status: "sent",
        whatsappMessageId: whatsappMessageId || null,
        messageType: mediaType,
        mediaUrl: mediaUrl || null,
        fileName: fileName || null,
        caption: caption || null,
      });

      await db.collection("chats").doc(chatId).update({
        lastMessage: messageContent,
        lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return {
      statusCode: 200,
      success: true,
      data: response.data,
      messageId: whatsappMessageId,
    };
  }
  catch (err) {
    const errData = err.response?.data ?? err.message;
    logger.error("INTERAKT ERROR:", errData);

    return {
      statusCode: 500,
      success: false,
      message: errData,
    };
  }
}

// ============================================================
// 📤 UPLOAD MEDIA TO FIREBASE STORAGE
// ============================================================
const uploadMediaForChat = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");
  if (req.method === "OPTIONS") return res.status(200).end();

  try {
    const { fileName, mimeType, base64File } = req.body;

    if (!fileName || !mimeType || !base64File) {
      return res.status(400).json({
        success: false,
        message: "Missing required fields",
      });
    }

    const buffer = Buffer.from(base64File, "base64");
    const bucket = admin.storage().bucket();
    const file = bucket.file(`chat_media/${Date.now()}_${fileName}`);

    await file.save(buffer, {
      metadata: { contentType: mimeType },
      public: true,
    });

    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${file.name}`;

    return res.json({
      success: true,
      url: publicUrl,
      fileName: fileName,
    });
  } catch (error) {
    logger.error("Upload media error:", error);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// ============================================================
// 📊 UPDATE MESSAGE STATUS
// ============================================================
const updateMessageStatus = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");
  if (req.method === "OPTIONS") return res.status(200).end();

  try {
    const { whatsappMessageId, status } = req.body;

    if (!whatsappMessageId || !status) {
      return res.status(400).json({
        success: false,
        message: "WhatsApp message ID and status are required",
      });
    }

    const chatsSnapshot = await db.collection("chats").get();

    for (const chatDoc of chatsSnapshot.docs) {
      const messagesQuery = await chatDoc.ref
        .collection("messages")
        .where("whatsappMessageId", "==", whatsappMessageId)
        .limit(1)
        .get();

      if (!messagesQuery.empty) {
        const messageDoc = messagesQuery.docs[0];
        await messageDoc.ref.update({ status });
        logger.info(`Updated message ${whatsappMessageId} status to ${status}`);
        break;
      }
    }

    return res.json({ success: true });
  } catch (error) {
    logger.error("Update status error:", error);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// ============================================================
// 📊 NEW: GET DAILY STATS
// ============================================================
const getDailyStats = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");
  if (req.method === "OPTIONS") return res.status(200).end();

  try {
    const { date } = req.query;

    if (!date) {
      return res.status(400).json({
        success: false,
        message: "Date parameter required (format: YYYY-MM-DD)",
      });
    }

    const statsDoc = await db.collection("totalSendMsg").doc(date).get();

    if (!statsDoc.exists) {
      return res.json({
        success: true,
        data: {
          date: date,
          totalSent: 0,
          totalDelivered: 0,
          totalRead: 0
        },
      });
    }

    return res.json({
      success: true,
      data: statsDoc.data(),
    });
  } catch (error) {
    logger.error("Error getting daily stats:", error);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// ============================================================
// 📊 NEW: INCREMENT DAILY STATISTICS HELPER
// ============================================================
async function incrementDailyStats(date, type) {
  try {
    const statsRef = db.collection('totalSendMsg').doc(date);
    const increment = admin.firestore.FieldValue.increment(1);

    const updateData = {
      date: date,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (type === 'sent') {
      updateData.totalSent = increment;
    } else if (type === 'delivered') {
      updateData.totalDelivered = increment;
    } else if (type === 'read') {
      updateData.totalRead = increment;
    }

    await statsRef.set(updateData, { merge: true });
    logger.info(`📊 Daily stats updated for ${date}: ${type}`);
  } catch (error) {
    logger.error('❌ Error updating daily stats:', error);
  }
}

module.exports = {
  sendWhatsAppMessage,
  uploadMediaForChat,
  updateMessageStatus,
  getDailyStats,
  sendWhatsAppMessageHelper
};