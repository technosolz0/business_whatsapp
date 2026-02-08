const { setGlobalOptions } = require("firebase-functions");
const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const axios = require("axios");
require("dotenv").config();
const admin = require("firebase-admin");
const { getSecrets } = require("./utils");

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}
setGlobalOptions({ maxInstances: 10 });

const BASE_URL = process.env.BASE_URL;
const INTERAKT_TOKEN = process.env.INTERAKT_TOKEN;

const db = admin.firestore();

// ============================================================
// 🚀 SEND WHATSAPP MESSAGE (TEXT, IMAGE, DOCUMENT) - WITH STATS
// ============================================================
const sendWhatsAppMessage = onRequest({ cors: true }, async (req, res) => {
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
    const { clientId, phoneNumber, message, chatId, messageType, mediaUrl, fileName, caption } = requestBody;

    const secrets = await getSecrets(clientId);

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

    const response = await axios.post(`${BASE_URL}/${secrets.phoneNumberId}/messages`, payload, {
      headers: {
        "x-access-token": INTERAKT_TOKEN,
        "x-waba-id": secrets.wabaId,
        "Content-Type": "application/json",
      },
    });

    const whatsappMessageId = response.data?.messages?.[0]?.id;

    // 📊 NEW: Increment sent count
    const today = new Date().toISOString().split("T")[0];
    await incrementDailyStats(clientId, today, "sent");
    logger.info(`📊 Incremented sent count for ${today}`);

    // Store message in Firestore
    if (chatId) {
      const messageRef = db
        .collection("chats")
        .doc(clientId)
        .collection("data")
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

      await db.collection("chats").doc(clientId).collection("data").doc(chatId).update({
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
const uploadMediaForChat = onRequest({ cors: true }, async (req, res) => {
  if (req.method === "OPTIONS") return res.status(200).end();

  try {
    const { clientId, fileName, mimeType, base64File } = req.body;

    if (!fileName || !mimeType || !base64File) {
      return res.status(400).json({
        success: false,
        message: "Missing required fields",
      });
    }

    const buffer = Buffer.from(base64File, "base64");
    const bucket = admin.storage().bucket();
    const file = bucket.file(`chat_media/${clientId}/${Date.now()}_${fileName}`);

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
const updateMessageStatus = onRequest({ cors: true }, async (req, res) => {
  if (req.method === "OPTIONS") return res.status(200).end();

  try {
    const { clientId, whatsappMessageId, status } = req.body;

    if (!whatsappMessageId || !status) {
      return res.status(400).json({
        success: false,
        message: "WhatsApp message ID and status are required",
      });
    }

    const chatsSnapshot = await db.collection("chats").doc(clientId).collection("data").get();

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
const getDailyStats = onRequest({ cors: true }, async (req, res) => {
  if (req.method === "OPTIONS") return res.status(200).end();

  try {
    const { clientId, date } = req.query;

    if (!date) {
      return res.status(400).json({
        success: false,
        message: "Date parameter required (format: YYYY-MM-DD)",
      });
    }

    const statsDoc = await db.collection("totalSendMsg").doc(clientId).collection("data").doc(date).get();

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
async function incrementDailyStats(clientId, date, type) {
  try {
    const statsRef = db.collection('totalSendMsg').doc(clientId).collection("data").doc(date);
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