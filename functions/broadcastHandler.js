const { setGlobalOptions } = require("firebase-functions");
const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const axios = require("axios");
require("dotenv").config();
const admin = require("firebase-admin");
const { PubSub } = require('@google-cloud/pubsub');
const { CloudTasksClient, protos } = require('@google-cloud/tasks');
const { refundMessageCost } = require("./webhookHandler");

admin.initializeApp();
setGlobalOptions({ maxInstances: 10 });

const FormData = require("form-data");
const WABA_ID = process.env.WABA_ID;
const PHONENUMBERID = process.env.PHONENUMBERID;
const TOKEN = process.env.INTERAKT_TOKEN;
const PROJECT_ID = process.env.PROJECT_ID;
const REGION = process.env.REGION;
const SEND_MESSAGE_URL = `https://amped-express.interakt.ai/api/v24.0/${PHONENUMBERID}/messages`;
const db = admin.firestore();
const pubSubClient = new PubSub();
const cloudTasksClient = new CloudTasksClient();


const sendWhatsAppTemplateMessage = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");
  if (req.method === "OPTIONS") return res.status(200).end();

  try {
    const response = await sendWhatsAppTemplateMessageHelper(req.body);

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
})

async function
  sendWhatsAppTemplateMessageHelper(payload) {
  try {
    const {
      template,
      language,
      type, // text -> Text, media -> Text & Media
      bodyVariables, // [string]
      headerVariables, // {type: text/image/video/document, data: {text: string, mediaId: string, fileName: string}}
      buttonVariables,
      mobileNo
    } = payload;

    switch (type.toUpperCase()) {
      case "TEXT":
        payload = generateTextTemplatePayload(template, mobileNo, language, bodyVariables, headerVariables);
        break;

      case "MEDIA":
        payload = generateMediaTemplatePayload(template, mobileNo, language, bodyVariables, headerVariables);
        break;

      case "INTERACTIVE":
        payload = generateInteractiveTemplatePayload(template, mobileNo, language, bodyVariables, headerVariables, buttonVariables);
        break;

      default:
        return { statusCode: 400, success: false, message: "Invalid type" };
    }

    logger.info("Sending WhatsApp message:", payload);

    const response = await axios.post(SEND_MESSAGE_URL, payload, {
      headers: {
        "x-access-token": TOKEN,
        "x-waba-id": WABA_ID,
        "Content-Type": "application/json",
      },
    });

    return {
      statusCode: 200,
      success: true,
      data: response.data,
    };

  } catch (err) {
    const errData = err.response?.data ?? err.message;

    logger.error("INTERAKT ERROR:", errData);

    return {
      statusCode: 500,
      success: false,
      message: errData,
    };
  }
}

function generateTextTemplatePayload(template, mobileNo, language, parameters, headerParameters) {

  const headerParam = headerParameters && headerParameters.data && headerParameters.data.type === "text" ? {
    type: "text",
    text: headerParameters.data.text
  } : null;

  const bodyParams = parameters.map(x => ({
    type: "text",
    text: x
  }));

  const components = [];

  if (headerParam) {
    components.push({
      type: "header",
      parameters: [headerParam]
    });
  }

  if (bodyParams.length > 0) {
    components.push({
      type: "body",
      parameters: bodyParams
    });
  }

  const payload = {
    messaging_product: "whatsapp",
    recipient_type: "individual",
    to: mobileNo,
    type: "template",
    template: {
      name: template,
      language: { code: language }
    }
  };

  if (components.length > 0) {
    payload.template.components = components;
  }

  return JSON.stringify(payload);
}

function generateMediaTemplatePayload(template, mobileNo, language, parameters, headerParameters) {

  const headerParam = {
    type: headerParameters.type.toLowerCase(),
    [headerParameters.type.toLowerCase()]: {
      id: headerParameters.data.mediaId,
      ...(headerParameters.type.toLowerCase() === "document" && { filename: headerParameters.data.fileName })
    }
  };

  const bodyParams = parameters.map(x => ({
    type: "text",
    text: x
  }));

  const components = [{
    type: "header",
    parameters: [headerParam]
  }];

  if (bodyParams.length > 0) {
    components.push({
      type: "body",
      parameters: bodyParams
    });
  }

  return JSON.stringify({
    messaging_product: "whatsapp",
    recipient_type: "individual",
    to: mobileNo,
    type: "template",
    template: {
      name: template,
      language: { code: language },
      components: components
    }
  });
}

function generateInteractiveTemplatePayload(template, mobileNo, language, parameters, headerParameters, buttonParameters) {
  const headerParam = headerParameters ?
    headerParameters.type === "text" ?
      {
        type: "text",
        text: headerParameters.data.text
      }
      :
      {
        type: headerParameters.type.toLowerCase(),
        [headerParameters.type.toLowerCase()]: {
          id: headerParameters.data.mediaId,
          ...(headerParameters.type.toLowerCase() === "document" && { filename: headerParameters.data.fileName })
        }
      }
    :
    null;

  const bodyParams = parameters.map(x => ({
    type: "text",
    text: x
  }));

  const buttonParams = buttonParameters.map((btn, index) => {
    switch (btn.type.toLowerCase()) {
      case "quick_reply":
        return {
          type: "button",
          sub_type: "quick_reply",
          index: index.toString(),
          parameters: [{
            type: "payload",
            payload: btn.payload ? btn.payload : "payload"
          }]
        };
      case "url":
        return btn.payload ? {
          type: "button",
          sub_type: "url",
          index: index.toString(),
          parameters: [{
            type: "payload",
            payload: btn.payload
          }]
        } : null;
      case "phone_number":
        return null;
      case "copy_code":
        return {
          type: "button",
          sub_type: "copy_code",
          index: index.toString(),
          parameters: [{
            type: "coupon_code",
            coupon_code: btn.payload
          }]
        };
    }
  }).filter(btn => btn !== null);

  const components = [];

  if (headerParam) {
    components.push({
      type: "header",
      parameters: [headerParam]
    });
  }

  if (bodyParams.length > 0) {
    components.push({
      type: "body",
      parameters: bodyParams
    });
  }

  if (buttonParams.length > 0) {
    buttonParams.forEach(buttonParam => {
      components.push(buttonParam);
    });
  }

  const payload = {
    messaging_product: "whatsapp",
    recipient_type: "individual",
    to: mobileNo,
    type: "template",
    template: {
      name: template,
      language: { code: language }
    }
  };

  if (components.length > 0) {
    payload.template.components = components;
  }

  return JSON.stringify(payload);

}

const pubMessagesToTopic = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");
  if (req.method === "OPTIONS") return res.status(200).end();

  try {
    const { broadcastId, isScheduled, scheduledTimestamp } = req.body;

    const broadcast = await db.collection("broadcasts").doc(broadcastId).get();
    if (!broadcast.exists) {
      return res.status(404).json({ success: false, message: "Broadcast not found" });
    }

    //Updating Wallet
    const broadcastData = broadcast.data();
    await updateWallet(broadcastId, broadcastData);

    if (isScheduled) {
      // Schedule 'pubScheduledMessagesToTopic' via Cloud Tasks
      const scheduledTime = new Date(scheduledTimestamp);
      const secondsSinceEpoch = Math.round(scheduledTime.getTime() / 1000);

      const parent = cloudTasksClient.queuePath(PROJECT_ID, REGION, 'broadcast-scheduler');
      const payload = { broadcastId }; // Set isScheduled to false for the target function
      const taskName = `schedule-broadcast-${broadcastId}-${scheduledTime.getTime()}`;

      const task = {
        httpRequest: {
          httpMethod: protos.google.cloud.tasks.v2.HttpMethod.POST,
          url: `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/pubScheduledMessagesToTopic`, // Replace with the actual URL of 'pubScheduledMessagesToTopic'
          // Base64 encode the JSON payload
          body: Buffer.from(JSON.stringify(payload)).toString("base64"),
          headers: {
            "Content-Type": "application/json",
          }
        },
        scheduleTime: {
          seconds: secondsSinceEpoch,
        },
        name: taskName
      };

      await cloudTasksClient.createTask({ parent, task });

      return res.status(200).json({
        success: true,
        message: `Broadcast scheduled successfully for ${scheduledTime.toISOString()}.`
      });
    }
    else {
      await pubMessagesToTopicAsync(broadcastId, false);
    }

    return res.status(200).json({ success: true, message: "All messages queued." });

  } catch (err) {
    console.error("Dispatch messages error:", err);
    return res.status(500).json({ success: false, message: err.message });
  }
});

const pubScheduledMessagesToTopic = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");
  if (req.method === "OPTIONS") return res.status(200).end();
  try {
    const { broadcastId } = req.body;

    await pubMessagesToTopicAsync(broadcastId, true);

    return res.status(200).json({ success: true, message: "All messages queued." });

  } catch (err) {
    console.error("Dispatch messages error:", err);
    return res.status(500).json({ success: false, message: err.message });
  }
});

async function pubMessagesToTopicAsync(broadcastId, isScheduled) {
  const batchSize = 500;
  let lastDoc = null;

  // Configure topic with automatic batching
  const topicName = !isScheduled
    ? "broadcast_messages"
    : `scheduled_broadcast_${broadcastId}`;


  if (isScheduled) {
    await pubSubClient.createTopic(topicName);
  }

  const topic = pubSubClient.topic(topicName, {
    batching: {
      maxMessages: 500,       // max messages per batch RPC
      maxMilliseconds: 500,   // max wait before sending batch
    },
  });

  if (isScheduled) {
    await topic.createSubscription(`send_scheduled_broadcast_message_${broadcastId}`, {
      pushConfig: {
        pushEndpoint: `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/sendBroadcastMessage`
      },
      ackDeadlineSeconds: 30
    });
  }

  console.info(`Publishing broadcast ${broadcastId} to topic ${topicName}`);

  // 1️⃣ START delimiter
  await topic.publishMessage({
    data: Buffer.from(JSON.stringify({ delimiter: "START", broadcastId, isScheduled })),
  });
  console.info("Published START delimiter");

  // 2️⃣ Firestore pagination loop
  while (true) {
    let query = db
      .collection("broadcasts")
      .doc(broadcastId)
      .collection("messages")
      .limit(batchSize);

    if (lastDoc) query = query.startAfter(lastDoc);

    const snapshot = await query.get();
    if (snapshot.empty) break;

    lastDoc = snapshot.docs[snapshot.docs.length - 1];

    const messages = snapshot.docs.map(doc => ({
      ...doc.data(),
    }));

    console.info(`Fetched ${messages.length} messages`);

    // Publish messages individually — batching handled automatically
    for (const msgObj of messages) {
      await topic.publishMessage({
        data: Buffer.from(JSON.stringify(msgObj)),
      });
    }
  }

  // 3️⃣ END delimiter
  await topic.publishMessage({
    data: Buffer.from(JSON.stringify({ delimiter: "END", broadcastId, isScheduled })),
  });
  console.info("Published END delimiter");
}

const sendBroadcastMessage = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");
  if (req.method === "OPTIONS") return res.status(200).end();

  try {
    logger.info(`Received Payload: ${req.body}`);

    const body = JSON.parse(Buffer.from(req.body.message.data, 'base64').toString('utf8'));

    const broadcastId = body.broadcastId;
    const broadcastDocRef = db.collection("broadcasts").doc(broadcastId);

    logger.info(`Dispatching broadcast messages... ${broadcastId}`);

    const updates = [];

    if (body.delimiter) {
      switch (body.delimiter.toUpperCase()) {
        case 'START':
          logger.info(`Broadcast ${broadcastId} started dispatching messages.`);
          updates.push(broadcastDocRef.update({ invocationSuccesses: 0, invocationFailures: 0, sent: 0, delivered: 0, read: 0, failed: 0, status: 'Sending' }));
          break;
        case 'END':
          logger.info(`Broadcast ${broadcastId} finished dispatching messages.`);
          updates.push(broadcastDocRef.update({ status: 'Sent', completedAt: admin.firestore.FieldValue.serverTimestamp() }));
          if (body.isScheduled) {
            updates.push(await pubSubClient.subscription(`send_scheduled_broadcast_message_${broadcastId}`).delete());
            updates.push(await pubSubClient.topic(`scheduled_broadcast_${broadcastId}`).delete());
          }
          break;
        default:
          logger.warn(`Unknown delimiter ${body.delimiter} for broadcast ${broadcastId}.`);
          break;
      }
    }
    else {
      const messageId = body.messageId;
      const messageDocRef = broadcastDocRef.collection("messages").doc(messageId);
      const payload = body.payload;
      const cost = body.cost;

      const response = await sendWhatsAppTemplateMessageHelper(payload);

      if (response.success) {
        const wamid = response.data.messages[0].id;
        updates.push(db.collection("wamid_broadcast_message_map").doc(wamid).set({
          broadcastId: broadcastId,
          messageId: messageId,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        }));
        updates.push(messageDocRef.update({ status: 'invocation_succeeded', invocationSucceededAt: admin.firestore.FieldValue.serverTimestamp(), addedToChat: false, wamId: wamid }));
        updates.push(broadcastDocRef.update({ invocationSuccesses: admin.firestore.FieldValue.increment(1) }));
        logger.info(`Message ${messageId} sent successfully.`);
      } else {
        updates.push(messageDocRef.update({ status: 'invocation_failed', errorCode: response.message, invocationFailedAt: admin.firestore.FieldValue.serverTimestamp() }));
        updates.push(broadcastDocRef.update({ invocationFailures: admin.firestore.FieldValue.increment(1)/*, totalCost: admin.firestore.FieldValue.increment(-cost)*/ }));

        //Refunding Cost of Failed Message
        updates.push(refundMessageCost(broadcastId, cost));

        logger.error(`Failed to send message ${messageId}: ${response.message}`);
      }

    }

    if (updates.length > 0) {
      await Promise.all(updates);
      console.log(`Success`);
    }
    return res.sendStatus(200);
  }
  catch (err) {
    logger.error("Dispatch messages error:", err.message);
    return res.status(500).json({
      success: false,
      message: err.message,
    });
  }
});

async function updateWallet(broadcastId, broadcastData) {
  const wallet = db.collection("profile").doc("wallet");
  await wallet.update({
    balance: admin.firestore.FieldValue.increment(-broadcastData.totalCost)
  });
  await wallet.collection("broadcast_history").doc(broadcastId).set({
    name: broadcastData.broadcastName,
    chargeable_messages: broadcastData.contactIds.length,
    chargeable_amount: broadcastData.totalCost,
    date: broadcastData.createdAt,
  });
}

module.exports = {
  sendWhatsAppTemplateMessage,
  pubMessagesToTopic,
  pubScheduledMessagesToTopic,
  sendBroadcastMessage,
  sendWhatsAppTemplateMessageHelper,
};