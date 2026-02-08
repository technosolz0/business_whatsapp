const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const axios = require("axios");
const { Filter } = require("firebase-admin/firestore");
const { sendWhatsAppMessageHelper } = require("./chatHandler");
const { getSecrets } = require("./utils");
const { generateContentWithFileSearch } = require("./geminiService");
const { parsePhoneNumberWithError } = require("libphonenumber-js");

require("dotenv").config();

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();
const bucket = admin.storage().bucket(); // Firebase Storage bucket

const BASE_URL = process.env.BASE_URL;
const INTERAKT_TOKEN = process.env.INTERAKT_TOKEN;


// -----------------------------------------------------
// 🔵 Webhook Handler Export
// -----------------------------------------------------
const interaktTemplateWebhook = onRequest({ memory: "2GiB", cors: true }, async (req, res) => {

  // ---------------------------
  // 1️⃣ Verification (GET)
  // ---------------------------
  if (req.method === "GET") {
    //const mode = req.query["hub.mode"];
    //const token = req.query["hub.verify_token"];
    const challenge = req.query["hub.challenge"];

    if (challenge) {
      //if (mode === "subscribe" && token === WEBHOOK_VERIFY_TOKEN) {
      return res.status(200).send(challenge);
    }
    return res.sendStatus(400);
  }

  // ---------------------------
  // 2️⃣ POST event handler
  // ---------------------------
  if (req.method === "POST") {
    try {
      const body = req.body;

      // 🔵 GLOBAL LOG (raw webhook)
      // await logWebhook("incoming_webhook", body);

      if (!body.entry || !Array.isArray(body.entry)) {
        logger.error("Invalid webhook body:", body);
        await logWebhook("invalid_payload", body, "ERROR");
        return res.sendStatus(200);
      }

      for (const entry of body.entry) {
        for (const change of entry.changes || []) {
          const field = change.field;
          const value = change.value;
          const phoneNumberId = value.metadata?.phone_number_id;

          switch (field) {

            case "message_template_status_update":
              await logWebhook(phoneNumberId, "status_update", value);
              await handleStatusUpdate(phoneNumberId, value);
              break;

            case "template_category_update":
              await logWebhook(phoneNumberId, "category_update", value);
              await handleCategoryUpdate(phoneNumberId, value);
              break;

            // ============================================
            // 💬 CHAT MESSAGES (NEW)
            // ============================================
            case "messages":
              if (value.statuses) {
                //await logWebhook(phoneNumberId, "message_status_update", value);
                await handleMessageStatusUpdate(phoneNumberId, value);
              } else {
                //await logWebhook(phoneNumberId, "chat_message", value);
                await handleChatMessage(phoneNumberId, value);
              }
              break;

            case "user_preferences":
              await logWebhook(phoneNumberId, "user_preference", value);
              await updateUserPreference(phoneNumberId, value)
              break;

            default:
              await logWebhook(phoneNumberId, "unknown_event", { field, value });
          }
        }
      }

      return res.sendStatus(200);

    } catch (err) {
      logger.error("WEBHOOK ERROR:", err);
      return res.sendStatus(200);
    }
  }
});

// -----------------------------------------------------
// 🟣 Firestore Logging Utility
// -----------------------------------------------------
async function logWebhook(clientId, type, payload, status = "SUCCESS") {
  try {
    await db.collection("webhook_logs").doc(clientId).collection("data").add({
      type,
      payload,
      status,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (err) {
    console.error("LOGGING ERROR:", err);
  }
}

// -----------------------------------------------------
// 🔵 Handlers
// -----------------------------------------------------



async function handleStatusUpdate(clientId, value) {
  const id = value.message_template_id?.toString();
  if (!id) return;

  let reasonBlock = null;

  // -----------------------------
  // 1️⃣ Disabled Template
  // -----------------------------
  if (value.disable_info) {
    reasonBlock = {
      type: "disable",
      info: {
        disable_date: value.disable_info.disable_date || null
      }
    };
  }

  // -----------------------------
  // 2️⃣ Other Info (locked / unlocked / paused / unpaused / etc.)
  // -----------------------------
  if (value.other_info) {
    reasonBlock = {
      type: "other_info",
      info: {
        title: value.other_info.title || null,
        description: value.other_info.description || null
      }
    };
  }

  // -----------------------------
  // 3️⃣ Rejection Info (INVALID_FORMAT etc.)
  // -----------------------------
  if (value.rejection_info) {
    reasonBlock = {
      type: "rejection_info",
      info: {
        reason: value.rejection_info.reason || null,
        recommendation: value.rejection_info.recommendation || null
      }
    };
  }

  const updateData = {
    status: value.event || "",
    category: value.message_template_category || "",
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  };

  // add only if present
  if (reasonBlock) {
    updateData.reason = reasonBlock;
  }

  await db.collection("templates").doc(clientId).collection("data").doc(id).set(updateData, { merge: true });
}


async function handleCategoryUpdate(clientId, value) {
  const id = value.message_template_id?.toString();
  if (!id) return;

  await db.collection("templates").doc(clientId).collection("data").doc(id).set({
    category: value.new_category || value.correct_category || "",
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });
}

// -----------------------------------------------------
//  CHAT MESSAGE HANDLER (ENHANCED WITH PERMANENT MEDIA STORAGE)
// -----------------------------------------------------
async function handleChatMessage(clientId, value) {
  try {
    const messages = value?.messages;

    if (!messages || messages.length === 0) {
      logger.info("No messages in webhook value");
      return;
    }

    const secrets = await getSecrets(clientId);

    for (const message of messages) {
      const fromPhone = message.from;
      const messageId = message.id;
      const timestamp = message.timestamp;
      const messageType = message.type;

      const { phoneNumber, countryCode } = extractPhoneNumber(fromPhone);

      logger.info(`Extracted - Phone: ${phoneNumber}, Country Code: ${countryCode}`);

      let messageText = "";
      let context = null;
      let mediaUrl = null;
      let fileName = null;
      let mimeType = null;
      let caption = null;

      // ————————————————————
      // HANDLE DIFFERENT MESSAGE TYPES WITH PERMANENT STORAGE
      // ————————————————————
      if (messageType === "text") {
        messageText = message.text?.body || "";
        context = message.text?.context || null;
      }

      else if (messageType === "image") {
        caption = message.image?.caption || "";
        messageText = caption || "📷 Image";
        mimeType = message.image?.mime_type || "image/jpeg";

        if (message.image?.id) {
          const uploaded = await downloadAndUploadMedia(
            clientId,
            secrets,
            message.image.id,
            mimeType,
            null,
            messageId
          );
          if (uploaded) {
            mediaUrl = uploaded.url;
            fileName = uploaded.filename;
          } else {
            messageText = "[Failed to save image]";
          }
        }
        context = message.image?.context || null;
      }

      else if (messageType === "document") {
        const doc = message.document;
        caption = doc?.caption || "";
        fileName = doc?.filename || "document";
        mimeType = doc?.mime_type || "application/octet-stream";
        messageText = caption || `📄 ${fileName}`;

        if (doc?.id) {
          const uploaded = await downloadAndUploadMedia(
            clientId,
            secrets,
            doc.id,
            mimeType,
            fileName,
            messageId
          );
          if (uploaded) {
            mediaUrl = uploaded.url;
            fileName = uploaded.filename;
          } else {
            messageText = `[Failed to save document: ${fileName}]`;
          }
        }
        context = message.document?.context || null;
      }

      else if (messageType === "video") {
        caption = message.video?.caption || "";
        messageText = caption || "🎥 Video";
        mimeType = message.video?.mime_type || "video/mp4";

        if (message.video?.id) {
          const uploaded = await downloadAndUploadMedia(
            clientId,
            secrets,
            message.video.id,
            mimeType,
            null,
            messageId
          );
          if (uploaded) {
            mediaUrl = uploaded.url;
            fileName = uploaded.filename;
          } else {
            messageText = "[Failed to save video]";
          }
        }
        context = message.video?.context || null;
      }

      else if (messageType === "audio" || messageType === "voice") {
        messageText = message.audio?.voice ? "🎤 Voice Message" : "🎵 Audio";
        mimeType = message.audio?.mime_type || "audio/ogg";

        if (message.audio?.id) {
          const uploaded = await downloadAndUploadMedia(
            clientId,
            secrets,
            message.audio.id,
            mimeType,
            message.audio?.voice ? `voice_${messageId}.ogg` : null,
            messageId
          );
          if (uploaded) {
            mediaUrl = uploaded.url;
            fileName = uploaded.filename;
          } else {
            messageText = "[Failed to save audio]";
          }
        }
        context = message.audio?.context || message.voice?.context || null;
      }

      else if (messageType === "button") {
        messageText = message.button?.text || "Button";
        context = message.button?.context || null;
      }

      else {
        logger.info(`Unsupported message type: ${messageType}`);
        continue;
      }

      logger.info(`Message from ${phoneNumber}: ${messageText} (${messageType})`);

      const contactQuery = await db
        .collection("contacts")
        .doc(clientId)
        .collection("data")
        .where("phoneNumber", "==", phoneNumber)
        .limit(1)
        .get();

      let contactId;
      let contactName = "Unknown User";

      if (!contactQuery.empty) {
        const contactDoc = contactQuery.docs[0];
        contactId = contactDoc.id;
        const contactData = contactDoc.data();
        contactName = `${contactData.fName || ""} ${contactData.lName || ""}`.trim();
      } else {
        const newContactRef = db.collection("contacts").doc(clientId).collection("data").doc();
        contactId = newContactRef.id;

        const profileName = value?.contacts?.[0]?.profile?.name;
        let fName = "";
        let lName = "";

        if (profileName) {
          const nameParts = profileName.split(" ");
          fName = nameParts[0] || "";
          lName = nameParts.slice(1).join(" ") || "";
        }

        await newContactRef.set({
          phoneNumber: phoneNumber,
          countryCode: countryCode,
          fName: fName,
          lName: lName,
          email: "",
          company: "",
          notes: "Auto-created from WhatsApp message",
          tags: [],
          status: null,
          lastContacted: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        contactName = fName || lName ? `${fName} ${lName}`.trim() : phoneNumber;
      }

      const chatRef = db.collection("chats").doc(clientId).collection("data").doc(contactId);
      const chatDoc = await chatRef.get();

      const fullPhoneNumber = `${countryCode}${phoneNumber}`;

      if (!chatDoc.exists) {
        await chatRef.set({
          name: contactName || phoneNumber,
          phoneNumber: fullPhoneNumber,
          avatarUrl: null,
          lastMessage: messageText,
          lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
          campaignName: null,
          isOnline: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          aiResponseEnabled: false,
          isActive: false,
          unRead: false
        });
      } else {
        const updateFields = {
          lastMessage: messageText,
          lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
          userLastMessageTime: admin.firestore.FieldValue.serverTimestamp()
        };
        if (!chatDoc.isActive) {
          updateFields.unRead = true;
        }
        await chatRef.update(updateFields);
      }

      let hasAiResponse = false;
      // AI Chat Response
      if (chatDoc.data()?.aiResponseEnabled) {

        await markMessageAsRead(secrets, messageId, true);

        if (messageType == 'text') {
          //Send AI Response
          await sendWhatsAppMessageHelper({
            clientId: clientId,
            phoneNumber: phoneNumber,
            message: await generateGeminiResponse(clientId, messageText, secrets.googleApiKey, [secrets.storeId, secrets.qnaStoreId], contactId),
            chatId: contactId,
            messageType: 'text',
          });
        }
        else {
          //Send Generic Response - Sorry, could not understand your request. Try again later.
          await sendWhatsAppMessageHelper({
            clientId: clientId,
            phoneNumber: phoneNumber,
            message: "Sorry, could not understand your request. Try again later.",
            chatId: contactId,
            messageType: 'text',
          });
        }
        hasAiResponse = true;
      }

      const broadcastColRef = db.collection("broadcasts").doc(clientId).collection("data");

      let { templateChatMessage, messageDocRef } = await broadcastMessageHelper(clientId, broadcastColRef, 'Sending', contactId, fullPhoneNumber);

      if (!templateChatMessage) {
        ({ templateChatMessage, messageDocRef } = await broadcastMessageHelper(clientId, broadcastColRef, 'Sent', contactId, fullPhoneNumber));
      }

      if (templateChatMessage) {
        logger.info(`Adding Template Chat Message: ${JSON.stringify(templateChatMessage)}`);
        await chatRef.collection("messages").doc().set(templateChatMessage);
        await messageDocRef.update({ addedToChat: true });
      }

      const messageRef = chatRef.collection("messages").doc();

      await messageRef.set({
        content: messageText,
        timestamp: admin.firestore.Timestamp.fromMillis(parseInt(timestamp) * 1000),
        isFromMe: false,
        senderName: contactName || phoneNumber,
        senderAvatar: null,
        status: hasAiResponse ? "read" : "delivered",
        whatsappMessageId: messageId,
        messageType: messageType,
        mediaUrl: mediaUrl,
        fileName: fileName,
        mimeType: mimeType,
        caption: caption,
        context: context,
      });

      logger.info(`Message stored successfully for contact ${contactId}${mediaUrl ? " [Media saved to Storage]" : ""}`);
    }
  } catch (error) {
    logger.error("Error handling chat message:", error);
    throw error;
  }
}

async function broadcastMessageHelper(clientId, broadcastColRef, status, contactId, fullPhoneNumber) {
  let templateChatMessage = null, messageDocRef = null;
  const broadcastQuery = broadcastColRef
    .where(
      Filter.or(
        Filter.and(
          Filter.where('audienceType', '==', 1),
          Filter.where('status', '==', status),
          Filter.where('contactIds', 'array-contains', fullPhoneNumber)
        ),
        Filter.and(
          Filter.where('audienceType', '!=', 1),
          Filter.where('status', '==', status),
          Filter.where('contactIds', 'array-contains', contactId)
        )
      ))
    .orderBy('deliveryTime.timestamp', 'desc')
    .limit(1);
  const broadcastColSnapshot = await broadcastQuery.get();
  if (!broadcastColSnapshot.empty) {
    const broadcastDocSnapshot = broadcastColSnapshot.docs[0];
    const broadcastData = broadcastDocSnapshot.data();

    const messageColRef = broadcastDocSnapshot.ref
      .collection("messages")
      .where(Filter.and(
        Filter.where('payload.mobileNo', '==', fullPhoneNumber),
        Filter.where('status', 'in', ['delivered', 'read']),
        Filter.where('addedToChat', '==', false)
      ));
    const messageColSnapshot = await messageColRef.get();

    if (!messageColSnapshot.empty) {
      const messageDocSnapshot = messageColSnapshot.docs[0];
      const messageData = messageDocSnapshot.data();
      messageDocRef = messageDocSnapshot.ref;

      const templateDocRef = db.collection('templates').doc(clientId).collection("data").doc(broadcastData.templateId);
      const templateDocSnapshot = await templateDocRef.get();
      const templateData = templateDocSnapshot.data();

      templateChatMessage = await createTemplateChatMessage(clientId, templateData, messageData, broadcastData, messageData.wamId, messageData.status, messageData.status == 'delivered' ? messageData.deliveredAt : messageData.readAt);
    }
  }
  return { templateChatMessage, messageDocRef };
}

async function generateGeminiResponse(clientId, prompt, apiKey, storeIds, sessionId = null) {
  return await generateContentWithFileSearch(clientId, prompt, apiKey, storeIds, "gemini-2.5-flash-lite", { maxOutputTokens: 500 }, sessionId, 10); // Limit to ~400-500 words, 10 messages context
}

function extractPhoneNumber(fullNumber) {
  const cleaned = fullNumber.replace(/\D/g, '');

  const countryCodes = [
    { code: '91', length: 2 },
    { code: '1', length: 1 },
    { code: '44', length: 2 },
    { code: '61', length: 2 },
    { code: '86', length: 2 },
    { code: '81', length: 2 },
    { code: '49', length: 2 },
    { code: '33', length: 2 },
    { code: '39', length: 2 },
    { code: '34', length: 2 },
    { code: '55', length: 2 },
    { code: '52', length: 2 },
    { code: '27', length: 2 },
    { code: '234', length: 3 },
    { code: '254', length: 3 },
    { code: '971', length: 3 },
    { code: '966', length: 3 },
    { code: '92', length: 2 },
    { code: '880', length: 3 },
    { code: '94', length: 2 },
    { code: '977', length: 3 },
  ];

  for (const { code, length } of countryCodes) {
    if (cleaned.startsWith(code)) {
      const phoneNumber = cleaned.substring(length);
      const countryCode = `+${code}`;
      return { phoneNumber, countryCode };
    }
  }

  if (cleaned.length > 10) {
    const countryCodeLength = cleaned.length - 10;
    const countryCode = `+${cleaned.substring(0, countryCodeLength)}`;
    const phoneNumber = cleaned.substring(countryCodeLength);
    return { phoneNumber, countryCode };
  }

  return { phoneNumber: cleaned, countryCode: '+91' };
}

// -----------------------------------------------------
// 📊 Status Updates with Daily Stats Tracking
// -----------------------------------------------------
async function handleMessageStatusUpdate(clientId, value) {
  try {
    const statuses = value.statuses;
    if (!statuses || !Array.isArray(statuses)) return;

    logger.info(`📊 Processing ${statuses.length} status update(s)`);

    for (const statusObj of statuses) {
      const whatsappMessageId = statusObj.id;
      const status = statusObj.status; // "sent" | "delivered" | "read" | "failed"
      const timestamp = statusObj.timestamp;
      const billable = statusObj.pricing?.billable ?? null;

      if (!whatsappMessageId) continue;

      logger.info(`🔄 Updating status for: ${whatsappMessageId} → ${status}`);

      // Get TODAY'S date (when status changed)
      const statusDate = new Date().toISOString().split('T')[0];

      const mapDocSnapshot = await db.collection("wamid_broadcast_message_map").doc(clientId).collection("data").doc(whatsappMessageId).get();

      logger.info(`Exists in Broadcast Message Map: ${mapDocSnapshot.exists}, Path: ${mapDocSnapshot.ref.path}`);
      if (mapDocSnapshot.exists) {
        const data = mapDocSnapshot.data();
        const { broadcastId, messageId } = data;

        // Get broadcasts document reference and message document
        const broadcastDocRef = db.collection("broadcasts").doc(clientId).collection("data").doc(broadcastId);
        //const broadcastDocSnapshot = await broadcastDocRef.get();
        const messageDocRef = broadcastDocRef.collection("messages").doc(messageId);
        const messageDocSnapshot = await messageDocRef.get();

        if (!messageDocSnapshot.exists) {
          console.log(`Message document ${messageId} in broadcast ${broadcastId} not found.`);
          continue; // Stop execution if message doc doesn't exist
        }

        const messageData = messageDocSnapshot.data();

        if (messageData.status === status) {
          console.log(`Status for message ${messageId} is already ${status}, skipping update.`);
          continue; // Skip if status is already the same
        }

        const statusTimestamp = admin.firestore.Timestamp.fromMillis(parseInt(timestamp) * 1000);
        const updates = [];

        // Perform updates based on status
        switch (status.toLowerCase()) {
          case 'failed':
            // ✅ FIX: Using 'failed' increment instead of 'read' increment
            updates.push(messageDocRef.update({
              status: 'failed',
              errorCode: statusObj.errors[0].code,
              failedAt: timestamp // Using failedAt for clarity, though sentAt was in original
            }));
            updates.push(broadcastDocRef.update({ failed: admin.firestore.FieldValue.increment(1) }));

            //Refunding Cost of Failed Message
            updates.push(refundMessageCost(clientId, broadcastId, messageData.cost));

            updates.push(incrementDailyStats(clientId, statusDate, 'failed'));
            break;

          case 'sent':
            await messageDocRef.update({ status: 'sent', sentAt: statusTimestamp });
            updates.push(broadcastDocRef.update({ sent: admin.firestore.FieldValue.increment(1) }));

            if (!billable) {
              //Refunding Cost of Unbillable Message
              updates.push(refundMessageCost(clientId, broadcastId, messageData.cost));
            }

            updates.push(incrementDailyStats(clientId, statusDate, 'sent'));
            break;

          case 'delivered':
            await messageDocRef.update({ status: 'delivered', deliveredAt: statusTimestamp });
            updates.push(broadcastDocRef.update({ delivered: admin.firestore.FieldValue.increment(1) }));
            updates.push(incrementDailyStats(clientId, statusDate, 'delivered'));
            break;

          case 'read':
            // if (messageData.status === 'sent') {
            //   updates.push(messageDocRef.update({ deliveredAt: statusTimestamp }));
            //   updates.push(broadcastDocRef.update({ delivered: admin.firestore.FieldValue.increment(1) }));
            //   updates.push(incrementDailyStats(clientId, statusDate, 'delivered'));
            // }
            await messageDocRef.update({ status: 'read', readAt: statusTimestamp });
            updates.push(broadcastDocRef.update({ read: admin.firestore.FieldValue.increment(1) }));
            updates.push(incrementDailyStats(clientId, statusDate, 'read'));
            break;

          default:
            console.log(`Unknown status: ${status}`);
            break;
        }

        // Wait for all updates to complete
        if (updates.length > 0) {
          await Promise.all(updates);
          console.log(`Successfully processed status ${status} for message ${messageId}.`);
        }
        break; // Move to next statusObj after processing mapped broadcast message
      }

      // Search across all chats for this message ID
      const chatsSnapshot = await db.collection("chats").doc(clientId).collection("data").get();

      let updated = false;

      for (const chatDoc of chatsSnapshot.docs) {
        const messagesQuery = await chatDoc.ref
          .collection("messages")
          .where("whatsappMessageId", "==", whatsappMessageId)
          .limit(1)
          .get();

        if (!messagesQuery.empty) {
          const messageDoc = messagesQuery.docs[0];

          // Only update if new status is "higher priority"
          const currentStatus = messageDoc.data().status || "sent";
          const statusPriority = { sent: 1, delivered: 2, read: 3, failed: 1 };
          const newPriority = statusPriority[status] || 1;
          const currentPriority = statusPriority[currentStatus] || 1;

          if (newPriority >= currentPriority) {
            const updateData = {
              status: status,
              statusTimestamp: admin.firestore.Timestamp.fromMillis(parseInt(timestamp) * 1000),
            };

            if (status === 'failed') {
              updateData.errorCode = statusObj.errors[0].code;
              updateData.errorDescription = statusObj.errors[0].error_data.details;
              updateData.failedAt = admin.firestore.Timestamp.fromMillis(parseInt(timestamp) * 1000);
            }

            // 📊 Add timestamps and increment daily stats
            if (status === 'delivered') {
              updateData.deliveredAt = admin.firestore.Timestamp.fromMillis(parseInt(timestamp) * 1000);
              logger.info(`✅ Incrementing delivered count for ${statusDate}`);
              await incrementDailyStats(clientId, statusDate, 'delivered');
            } else if (status === 'read') {
              updateData.readAt = admin.firestore.Timestamp.fromMillis(parseInt(timestamp) * 1000);
              logger.info(`✅ Incrementing read count for ${statusDate}`);
              await incrementDailyStats(clientId, statusDate, 'read');
            }

            await messageDoc.ref.update(updateData);

            logger.info(`✅ Updated message ${whatsappMessageId} → ${status}`);
          }

          updated = true;
          break; // Found and updated
        }
      }

      if (!updated) {
        logger.info(`⚠️ Message ID ${whatsappMessageId} not found in any chat (status: ${status})`);
      }
    }
  } catch (error) {
    logger.error("❌ Error in handleMessageStatusUpdate:", error);
  }
}

// ============================================================
// 📊 INCREMENT DAILY STATISTICS HELPER
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
    } else if (type === 'failed') {
      updateData.totalFailed = increment;
    }

    await statsRef.set(updateData, { merge: true });
    logger.info(`📊 Daily stats updated for ${date}: ${type}`);
  } catch (error) {
    logger.error('❌ Error updating daily stats:', error);
  }
}

// ============================================================
// 🎬 ENHANCED: Download Media & Upload to Firebase Storage
// ============================================================
async function downloadAndUploadMedia(clientId, secrets, mediaId, mimeType, originalFilename = null, messageId) {
  const maxRetries = 2;
  let lastError = null;

  for (let retry = 0; retry <= maxRetries; retry++) {
    try {
      logger.info(`[Media ${mediaId}] Attempt ${retry + 1}: Fetching signed URL...`);

      // STEP 1: Fetch signed URL
      const metaRes = await axios.get(`${BASE_URL}/${secrets.phoneNumberId}/media/${mediaId}`, {
        headers: {
          "x-access-token": INTERAKT_TOKEN,
          "x-waba-id": secrets.wabaId,
          "Content-Type": "application/json",
        },
        timeout: 20000 + (retry * 5000),
      });

      const signedUrl = metaRes.data?.url;
      if (!signedUrl) {
        throw new Error(`No signed URL in response: ${JSON.stringify(metaRes.data)}`);
      }

      logger.info(`[Media ${mediaId}] Signed URL fetched: ${signedUrl.substring(0, 100)}...`);

      // STEP 2: Download binary
      const downloadRes = await axios.get(`${BASE_URL}/${secrets.phoneNumberId}/media?url=${signedUrl}`, {
        headers: {
          "x-access-token": INTERAKT_TOKEN,
          "x-waba-id": secrets.wabaId,
          "Content-Type": "application/json",
        },
        responseType: "arraybuffer",
        timeout: 90000 + (retry * 10000),
        maxContentLength: 100 * 1024 * 1024,
      });

      const buffer = Buffer.from(downloadRes.data);
      const fileSize = buffer.length;

      if (fileSize === 0) throw new Error("Downloaded empty file");
      if (fileSize > 100 * 1024 * 1024) throw new Error(`File too large: ${fileSize} bytes`);

      logger.info(`[Media ${mediaId}] Downloaded ${fileSize} bytes (MIME: ${mimeType})`);

      // STEP 3: Generate safe path & upload
      const ext = mimeType ? mimeType.split("/")[1]?.split("+")[0] || "file" : "file";
      const timestamp = Date.now();
      const random = Math.random().toString(36).substring(2, 8);
      const safeOriginal = originalFilename ? originalFilename.replace(/[^a-zA-Z0-9._-]/g, "_") : null;
      const finalFilename = safeOriginal || `${(messageId || mediaId).substring(-8)}_${timestamp}_${random}.${ext}`;

      const year = new Date().getFullYear();
      const month = String(new Date().getMonth() + 1).padStart(2, "0");
      const filePath = `whatsapp_media/${clientId}/${year}/${month}/${finalFilename}`;

      const file = bucket.file(filePath);
      await file.save(buffer, {
        metadata: {
          contentType: mimeType || "application/octet-stream",
          metadata: {
            originalFilename: originalFilename || null,
            originalSize: fileSize
          }
        },
        public: true,
        gzip: true,
      });

      const publicUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(filePath)}?alt=media`;

      // Verify upload exists
      const [metadata] = await file.getMetadata();

      if (!metadata.size || metadata.size === 0) {
        throw new Error("Upload verification failed: file has no size");
      }

      logger.info(`[Media ${mediaId}] ✅ Uploaded to: ${publicUrl} (original: ${fileSize} bytes, stored: ${metadata.size} bytes)`);

      return {
        url: publicUrl,
        filename: originalFilename || finalFilename,
        mimeType,
        size: fileSize,
      };

    } catch (err) {
      lastError = err;
      logger.warn(`[Media ${mediaId}] Attempt ${retry + 1} failed: ${err.message}`);

      if (err.response) {
        logger.error(`[Media ${mediaId}] HTTP ${err.response.status}: ${JSON.stringify(err.response.data, null, 2).substring(0, 500)}`);
      } else if (err.code === 'ECONNABORTED') {
        logger.error(`[Media ${mediaId}] Timeout after ${err.config?.timeout}ms`);
      } else {
        logger.error(`[Media ${mediaId}] Network/Other error: ${err.message}\nStack: ${err.stack}`);
      }

      if (err.response?.status >= 400 && err.response?.status < 500) {
        break;
      }

      if (retry < maxRetries) {
        await new Promise(resolve => setTimeout(resolve, 2000 * (retry + 1)));
      }
    }
  }

  logger.error("MEDIA DOWNLOAD FAILED (all retries):", {
    mediaId,
    error: lastError?.message,
    code: lastError?.code,
    status: lastError?.response?.status,
    response: lastError?.response?.data ? JSON.stringify(lastError.response.data).substring(0, 1000) : null,
  });

  return null;
}

async function createTemplateChatMessage(clientId, templateData, messageData, broadcastData, whatsappMessageId, status, statusTimestamp) {
  let templateMessage;
  switch (messageData.payload.type.toUpperCase()) {
    case 'TEXT':
      templateMessage = {
        caption: null,
        header: templateData.components[0].text || null,
        content: templateData.components[1].text.replace(/{{(\d+)}}/g, (_, index) => {
          return messageData.payload.bodyVariables[index - 1];
        }),
        footer: templateData.components[2].text || null,
        fileName: null,
        isFromMe: true,
        mediaUrl: null,
        isTemplateMessage: true,
        messageType: 'text',
        senderAvatar: null,
        senderName: broadcastData.adminName,
        status: status,
        statusTimestamp: statusTimestamp,
        timestamp: statusTimestamp,
        whatsappMessageId: whatsappMessageId,
      };
      break;
    case 'MEDIA':
      const filePath = `broadcasts_media/${clientId}/${broadcastData.attachmentId}/${messageData.payload.headerVariables.data.fileName}`;
      templateMessage = {
        caption: null,
        header: null,
        content: templateData.components[1].text.replace(/{{(\d+)}}/g, (_, index) => {
          return messageData.payload.bodyVariables[index - 1];
        }),
        footer: templateData.components[2].text || null,
        fileName: messageData.payload.headerVariables.data.fileName,
        isFromMe: true,
        mediaUrl: `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(filePath)}?alt=media`,
        isTemplateMessage: true,
        messageType: messageData.payload.headerVariables.type.toLowerCase(),
        senderAvatar: null,
        senderName: broadcastData.adminName,
        status: status,
        statusTimestamp: statusTimestamp,
        timestamp: statusTimestamp,
        whatsappMessageId: whatsappMessageId,
      };
      break;
    case 'INTERACTIVE':
      let header = null, fileName = null, mediaUrl = null;
      if (messageData.payload.headerVariables) {
        if (messageData.payload.headerVariables.type === 'text') {
          header = templateData.components[0].text;
        }
        else {
          fileName = messageData.payload.headerVariables.data.fileName;
          const filePath = `broadcasts_media/${clientId}/${broadcastData.attachmentId}/${fileName}`;
          mediaUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(filePath)}?alt=media`;
        }
      }
      templateMessage = {
        caption: null,
        header: header,
        content: templateData.components[1].text.replace(/{{(\d+)}}/g, (_, index) => {
          return messageData.payload.bodyVariables[index - 1];
        }),
        footer: templateData.components[2].text || null,
        buttons: templateData.components[3].buttons.map(button => {
          return {
            type: button.type,
            text: button.text,
          };
        }),
        fileName: fileName,
        isFromMe: true,
        mediaUrl: mediaUrl,
        isTemplateMessage: true,
        messageType: 'interactive',
        senderAvatar: null,
        senderName: broadcastData.adminName,
        status: status,
        statusTimestamp: statusTimestamp,
        timestamp: statusTimestamp,
        whatsappMessageId: whatsappMessageId,
      };
      break;
  }
  switch (status) {
    case 'delivered':
      templateMessage.deliveredAt = statusTimestamp;
      break;
    case 'read':
      templateMessage.readAt = statusTimestamp;
      break;
  }
  return templateMessage;
}

async function addMessageToChat(clientId, fromPhone, message) {

  logger.info(`Adding message to chat for phone: ${JSON.stringify(message)}`);

  const { phoneNumber, countryCode } = extractPhoneNumber(fromPhone.slice(1)); // Remove leading '+' if present

  const contactQuery = await db
    .collection("contacts")
    .doc(clientId)
    .collection("data")
    .where(Filter.and(Filter.where('countryCode', '==', countryCode), Filter.where("phoneNumber", "==", phoneNumber)))
    .limit(1)
    .get();

  let contactId;
  let contactName = "Unknown User";

  if (!contactQuery.empty) {
    const contactDoc = contactQuery.docs[0];
    contactId = contactDoc.id;
    const contactData = contactDoc.data();
    contactName = `${contactData.fName || ""} ${contactData.lName || ""}`.trim();
  } else {
    const newContactRef = db.collection("contacts").doc(clientId).collection("data").doc();
    contactId = newContactRef.id;
    await newContactRef.set({
      phoneNumber: phoneNumber,
      countryCode: countryCode,
      fName: "",
      lName: "",
      email: "",
      company: "",
      notes: "Auto-created from WhatsApp message",
      tags: [],
      status: null,
      lastContacted: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    contactName = phoneNumber;
  }

  const chatRef = db.collection("chats").doc(clientId).collection("data").doc(contactId);
  const chatDoc = await chatRef.get();

  const fullPhoneNumber = `${countryCode}${phoneNumber}`;

  if (!chatDoc.exists) {
    await chatRef.set({
      name: contactName || phoneNumber,
      phoneNumber: fullPhoneNumber,
      avatarUrl: null,
      lastMessage: message.content,
      lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
      campaignName: null,
      isOnline: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } else {
    await chatRef.update({
      lastMessage: message.content,
      lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  const messageRef = chatRef.collection("messages").doc();
  await messageRef.set(message);
}

/**
 * Get conversation analytics with dynamic filters
 * @param {string} filter - Time filter: 'Today', 'This Month', 'Last Month', 'Last 6 Months', 'Custom Date Range'
 * @param {number} customStart - Custom start timestamp (optional)
 * @param {number} customEnd - Custom end timestamp (optional)
 */
const getConversationAnalytics = onRequest({ cors: true }, async (req, res) => {
  res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    return res.status(200).send();
  }

  try {
    const { clientId, filter = "This Month", customStart, customEnd } = req.query;
    const secrets = await getSecrets(clientId);

    // Calculate start and end timestamps based on filter
    const { start, end, granularity } = getTimeRangeParams(
      filter,
      customStart,
      customEnd
    );

    logger.info(`Fetching analytics for ${filter}`, { start, end, granularity });

    // Fetch both analytics in parallel
    const [conversationData, messagesData] = await Promise.all([
      fetchConversationAnalytics(secrets, start, end, granularity),
      fetchMessagesAnalytics(secrets, start, end, granularity)
    ]);

    // Process data to calculate card metrics
    const metrics = processAnalyticsData(
      conversationData,
      messagesData
    );

    logger.info("Analytics processed successfully", metrics);

    return res.status(200).json({
      success: true,
      filter,
      dateRange: {
        start: new Date(start * 1000).toISOString(),
        end: new Date(end * 1000).toISOString(),
        granularity,
      },
      metrics,
      rawData: {
        conversations: conversationData,
        messages: messagesData
      }
    });

  } catch (error) {
    logger.error("Error fetching conversation analytics:", error);

    return res.status(500).json({
      success: false,
      error: error.message,
      details: error.response?.data || null,
    });
  }
});

/**
 * Fetch conversation analytics from API
 */
async function fetchConversationAnalytics(secrets, start, end, granularity) {
  // Always use DAILY granularity for conversation analytics to avoid monthly limitations
  const conversationGranularity = granularity === "DAY" ? "DAILY" : "MONTHLY";

  const analyticsUrl = `${BASE_URL}/${secrets.wabaId}?fields=conversation_analytics.start(${start}).end(${end}).granularity(${conversationGranularity}).phone_numbers([${secrets.phoneNumber}]).metric_types(['COST','CONVERSATION']).conversation_categories(['MARKETING','SERVICE','UTILITY']).conversation_types(['FREE_ENTRY_POINT','FREE_TIER','REGULAR','UNKNOWN']).conversation_directions(['BUSINESS_INITIATED','UNKNOWN']).dimensions(['CONVERSATION_TYPE','CONVERSATION_DIRECTION','CONVERSATION_CATEGORY'])`;

  const response = await axios.get(analyticsUrl, {
    headers: {
      "x-access-token": INTERAKT_TOKEN,
      "x-waba-id": secrets.wabaId,
      "Content-Type": "application/json",
    },
    timeout: 30000,
  });

  return response.data?.conversation_analytics?.data?.[0]?.data_points || [];
}

/**
 * Fetch messages analytics from API
 */
async function fetchMessagesAnalytics(secrets, start, end, granularity) {
  // Messages API uses DAY/MONTH and requires product_types
  const messagesGranularity = granularity;

  const analyticsUrl = `${BASE_URL}/${secrets.wabaId}?fields=analytics.start(${start}).end(${end}).granularity(${messagesGranularity}).phone_numbers([${secrets.phoneNumber}]).product_types([0,2])`;
  logger.info("Using Messages Analytics URL:", analyticsUrl);


  const response = await axios.get(analyticsUrl, {
    headers: {
      "x-access-token": INTERAKT_TOKEN,
      "x-waba-id": secrets.wabaId,
      "Content-Type": "application/json",
    },
    timeout: 30000,
  });

  return response.data?.analytics?.data_points || [];
}

/**
 * Calculate start, end timestamps and granularity based on filter
 */
function getTimeRangeParams(filter, customStart, customEnd) {
  const now = new Date();
  let start, end, granularity;

  switch (filter) {
    case "Today":
      // Start of today
      start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      end = now;
      granularity = "DAY";
      break;

    case "This Month":
      // Start of current month
      start = new Date(now.getFullYear(), now.getMonth(), 1);
      end = now;
      granularity = "DAY";
      break;

    case "Last Month":
      // Start and end of previous month
      const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      start = lastMonth;
      end = new Date(now.getFullYear(), now.getMonth(), 0); // Last day of previous month
      granularity = "DAY";
      break;

    case "Last 6 Months":
      // 6 months ago from today
      start = new Date(now.getFullYear(), now.getMonth() - 6, now.getDate());
      end = now;
      granularity = "MONTH";
      break;

    case "Custom Date Range":
      if (!customStart || !customEnd) {
        throw new Error("Custom date range requires customStart and customEnd parameters");
      }
      start = new Date(parseInt(customStart) * 1000);
      end = new Date(parseInt(customEnd) * 1000);

      // Determine granularity based on date range
      const daysDiff = (end - start) / (1000 * 60 * 60 * 24);
      granularity = daysDiff <= 31 ? "DAY" : "MONTH";
      break;

    default:
      // Default to This Month
      start = new Date(now.getFullYear(), now.getMonth(), 1);
      end = now;
      granularity = "DAY";
  }

  // Convert to Unix timestamps (seconds)
  return {
    start: Math.floor(start.getTime() / 1000),
    end: Math.floor(end.getTime() / 1000),
    granularity,
  };
}

/**
 * Process analytics data to calculate metrics for dashboard cards
 */
function processAnalyticsData(conversationDataPoints, allMessagesDataPoints) {
  let freeMessages = 0;
  let paidMessages = 0;
  let totalCost = 0;

  // All Messages data
  let totalSent = 0;
  let totalDelivered = 0;

  // Category breakdown for Messages Delivered card
  const deliveredByCategory = {
    marketing: 0,
    utility: 0,
    service: 0,
  };

  // Type breakdown for Free Messages card
  const freeMessagesByType = {
    customerService: 0,
    entryPoint: 0,
  };

  // Category breakdown for Paid Messages card
  const paidByCategory = {
    marketing: 0,
    utility: 0,
    service: 0,
  };

  // Category breakdown for Total Charges card
  const costByCategory = {
    marketing: 0,
    utility: 0,
    service: 0,
  };

  // Process conversation analytics data
  conversationDataPoints.forEach((point) => {
    const {
      conversation = 0,
      conversation_type,
      conversation_direction,
      conversation_category,
      cost = 0,
    } = point;

    // Only count if direction is UNKNOWN or BUSINESS_INITIATED
    if (conversation_direction !== "UNKNOWN" && conversation_direction !== "BUSINESS_INITIATED") {
      return;
    }

    const category = conversation_category?.toLowerCase() || "unknown";

    // 1. Messages Delivered - breakdown by CATEGORY only
    if (deliveredByCategory[category] !== undefined) {
      deliveredByCategory[category] += conversation;
    }

    // 2. Free Messages (FREE_ENTRY_POINT or FREE_TIER)
    if (conversation_type === "FREE_ENTRY_POINT" || conversation_type === "FREE_TIER") {
      freeMessages += conversation;

      if (conversation_type === "FREE_ENTRY_POINT") {
        freeMessagesByType.entryPoint += conversation;
      } else {
        freeMessagesByType.customerService += conversation;
      }
    }

    // 3. Paid Messages (REGULAR or UNKNOWN type)
    if (conversation_type === "REGULAR" || conversation_type === "UNKNOWN") {
      paidMessages += conversation;
      if (paidByCategory[category] !== undefined) {
        paidByCategory[category] += conversation;
      }
    }

    // 4. Total Charges (sum of all costs)
    totalCost += cost;
    if (costByCategory[category] !== undefined) {
      costByCategory[category] += cost;
    }
  });

  // Process all messages analytics data
  allMessagesDataPoints.forEach((point) => {
    totalSent += point.sent || 0;
    totalDelivered += point.delivered || 0;
  });

  // Calculate total delivered from category sum
  const totalDeliveredFromConversations = deliveredByCategory.marketing +
    deliveredByCategory.utility +
    deliveredByCategory.service;

  return {
    allMessages: {
      total: totalSent,
      breakdown: [
        { label: "Sent", value: totalSent },
        { label: "Delivered", value: totalDelivered },
      ],
    },
    messagesDelivered: {
      total: totalDeliveredFromConversations,
      breakdown: [
        { label: "Marketing", value: deliveredByCategory.marketing },
        { label: "Utility", value: deliveredByCategory.utility },
        { label: "Service", value: deliveredByCategory.service },
      ],
    },
    freeMessages: {
      total: freeMessages,
      breakdown: [
        { label: "Customer Service", value: freeMessagesByType.customerService },
        { label: "Entry Point", value: freeMessagesByType.entryPoint },
      ],
    },
    paidMessages: {
      total: paidMessages,
      breakdown: [
        { label: "Marketing", value: paidByCategory.marketing },
        { label: "Utility", value: paidByCategory.utility },
        { label: "Service", value: paidByCategory.service },
      ],
    },
    totalCharges: {
      total: totalCost.toFixed(2),
      currency: "₹",
      breakdown: [
        { label: "Marketing", value: costByCategory.marketing.toFixed(2) },
        { label: "Utility", value: costByCategory.utility.toFixed(2) },
        { label: "Service", value: costByCategory.service.toFixed(2) },
      ],
    },
  };
}

async function updateUserPreference(clientId, value) {
  const user_preference = value.user_preferences[0];
  let status;
  switch (user_preference.value.toLowerCase()) {
    case 'stop': status = 0; break;
    case 'resume': status = 1; break;
    default: return;
  }
  const { phoneNumber, countryCode } = extractPhoneNumber(user_preference.wa_id);
  const timestamp = admin.firestore.Timestamp.fromMillis(parseInt(user_preference.timestamp) * 1000);
  const contactsColSnapshot = await db.collection('contacts').doc(clientId).collection("data").where(Filter.and(Filter.where('countryCode', '==', countryCode), Filter.where('phoneNumber', '==', phoneNumber))).limit(1).get();
  if (contactsColSnapshot.empty) {
    return;
  }
  await contactsColSnapshot.docs[0].ref.update({ 'status': status, 'statusUpdatedAt': timestamp });
}

async function markMessageAsRead(secrets, messageId, addTypingIndicator) {
  try {
    const payload = {
      messaging_product: "whatsapp",
      status: "read",
      message_id: messageId,
    };
    if (addTypingIndicator) {
      payload.typing_indicator = {
        type: "text"
      };
    }
    await axios.post(`${BASE_URL}/${secrets.phoneNumberId}/messages`, payload, {
      headers: {
        "x-access-token": INTERAKT_TOKEN,
        "x-waba-id": secrets.wabaId,
        "Content-Type": "application/json",
      },
    });
    logger.info("Message marked as read successfully.");
  } catch (error) {
    logger.error("Error marking message as read:", error);
    throw error;
  }
}

async function refundMessageCost(clientId, broadcastId, cost) {
  const wallet = db.collection("profile").doc(clientId).collection("data").doc("wallet");
  await wallet.update({
    balance: admin.firestore.FieldValue.increment(cost)
  });
  await wallet.collection("broadcast_history").doc(broadcastId).update({
    chargeable_messages: admin.firestore.FieldValue.increment(-1),
    chargeable_amount: admin.firestore.FieldValue.increment(-cost)
  });
}

const getPhoneNumber = onRequest({ cors: true }, (req, res) => {
  if (req.method === "OPTIONS") {
    return res.status(200).send();
  }

  if (req.method !== "GET") {
    return res.status(405).send({ error: "Method not allowed" });
  }

  try {
    const phoneParam = req.query.phoneNumber;
    if (!phoneParam) {
      return res.status(400).send({ error: "Missing phoneNumber query parameter" });
    }

    let phoneNumber;
    let errorToThrow;

    // 1. Try parsing as international (prepend + if missing)
    try {
      const internationalParam = phoneParam.startsWith('+') ? phoneParam : `+${phoneParam}`;
      const parsedParams = parsePhoneNumberWithError(internationalParam);
      if (parsedParams.isValid()) {
        phoneNumber = parsedParams;
      }
    } catch (e) {
      errorToThrow = e;
    }

    // 2. If not valid international, try parsing with default country 'IN'
    if (!phoneNumber && !phoneParam.startsWith('+')) {
      try {
        const localParsed = parsePhoneNumberWithError(phoneParam, 'IN');
        if (localParsed.isValid()) {
          phoneNumber = localParsed;
        }
      } catch (e) {
        if (!errorToThrow) errorToThrow = e; // Keep first error if explicit
      }
    }

    // 3. Fallback: If neither is strictly "valid", but we had a successful parse, use it?
    // Or just throw if no valid number found. 
    // For now, if we still don't have phoneNumber, we try to use the one from International attempt if it parsed but was invalid?
    // No, better to return error if invalid.

    if (!phoneNumber) {
      // Re-throw the error or a generic invalid error
      throw errorToThrow || new Error("Invalid phone number");
    }

    res.send({
      countryCallingCode: phoneNumber.countryCallingCode,
      nationalNumber: phoneNumber.nationalNumber,
      number: phoneNumber.number, // full number
      country: phoneNumber.country
    });
  } catch (error) {
    logger.error("Error parsing phone number:", error);
    res.status(400).send({ error: "Invalid phone number format", details: error.message });
  }
});

module.exports = {
  getSecrets,
  interaktTemplateWebhook,
  getConversationAnalytics,
  refundMessageCost,
  getPhoneNumber
}