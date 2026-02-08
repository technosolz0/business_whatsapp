const { setGlobalOptions } = require("firebase-functions");
const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const axios = require("axios");
require("dotenv").config();
const admin = require("firebase-admin");
const { getSecrets } = require("./webhookHandler");

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}
const Busboy = require("busboy");
setGlobalOptions({ maxInstances: 10 });

const FormData = require("form-data");

const BASE_URL = process.env.BASE_URL;
const INTERAKT_TOKEN = process.env.INTERAKT_TOKEN;

const db = admin.firestore();


// Shubhangi ============================================================

const createInteraktTemplate = onRequest({ cors: true }, async (req, res) => {
  if (req.method === "OPTIONS") return res.status(200).end();

  try {
    const {
      clientId,
      name,
      language,
      category,
      body,
      bodyExampleValues,
      header,
      footer,
      isTextMedia,
      media_handle_id,
      mediaType,
      buttons,          // 🔥 NEW
      templateType      // 🔥 NEW (Text | Text & Media | Interactive)
    } = req.body;

    const secrets = await getSecrets(clientId);

    let components = [];

    // ------------------------------------------------------------
    // 🟣 HEADER COMPONENT (MEDIA OR TEXT)
    // ------------------------------------------------------------
    if (media_handle_id) {
      components.push({
        type: "HEADER",
        format: mediaType.toUpperCase(),
        example: {
          header_handle: [media_handle_id],
        },
      });
    } else if (header?.trim()) {
      components.push({
        type: "HEADER",
        format: "TEXT",
        text: header,
        example: {
          header_text: [header],
        },
      });
    }

    // ------------------------------------------------------------
    // 🔵 BODY COMPONENT
    // ------------------------------------------------------------
    const bodyComponent = {
      type: "BODY",
      text: body,
    };

    if (bodyExampleValues?.length > 0) {
      bodyComponent.example = {
        body_text: [bodyExampleValues],
      };
    }

    components.push(bodyComponent);

    // ------------------------------------------------------------
    // 🟡 FOOTER COMPONENT
    // ------------------------------------------------------------
    if (footer?.trim()) {
      components.push({
        type: "FOOTER",
        text: footer,
      });
    }

    // ------------------------------------------------------------
    // 🟢 BUTTONS COMPONENT (INTERACTIVE)
    // ------------------------------------------------------------
    if (buttons && Array.isArray(buttons) && buttons.length > 0) {
      const processedButtons = buttons.map((b) => {
        const mapped = {
          type: b.type,
          text: b.text
        };

        // --- URL ---
        if (b.type === "URL") {
          mapped.url = b.url;

          // If dynamic URL → include example              
          if (b.example && b.example.length > 0) {
            mapped.example = b.example[0]; // STRING ONLY
          }

          // If static URL → no example
        }

        // --- PHONE NUMBER ---
        else if (b.type === "PHONE_NUMBER") {
          mapped.phone_number = b.phone_number;
        }

        // --- COPY CODE ---
        else if (b.type === "COPY_CODE") {
          if (b.example && b.example.length > 0) {
            mapped.example = b.example[0];
          }
        }

        // --- QUICK REPLY ---
        // Only type & text

        return mapped;
      });

      components.push({
        type: "BUTTONS",
        buttons: processedButtons
      });
    }

    // ------------------------------------------------------------
    // 📦 FINAL TEMPLATE PAYLOAD (with templateType)
    // ------------------------------------------------------------
    const payload = {
      name,
      language,
      category: category.toUpperCase(),
      type: templateType || "Text", // 🔥 USE THE RECEIVED ONE
      components,
    };

    logger.info("FINAL PAYLOAD SENT:", payload);

    const response = await axios.post(`${BASE_URL}/${secrets.wabaId}/message_templates`, payload, {
      headers: {
        "x-access-token": INTERAKT_TOKEN,
        "x-waba-id": secrets.wabaId,
        "Content-Type": "application/json",
      },
    });

    return res.json({
      success: true,
      data: response.data,
    });

  } catch (err) {
    const errData = err.response?.data ?? err.message;
    logger.error("INTERAKT ERROR:", errData);

    return res.status(500).json({
      success: false,
      message: errData,
    });
  }
});

// ---------------------------------------------------------------
// 🟢 GET Interakt Templates WITH PAGINATION
// ---------------------------------------------------------------
const getInteraktTemplates = onRequest({ cors: true }, async (req, res) => {
  if (req.method === "OPTIONS") return res.status(200).end();

  try {
    // Read query params
    const { clientId, limit, after, before } = req.query;

    const secrets = await getSecrets(clientId);
    // Build params for Interakt API
    const params = {};

    if (limit) params.limit = limit;
    if (after) params.after = after;
    if (before) params.before = before;

    const response = await axios.get(`${BASE_URL}/${secrets.wabaId}/message_templates`, {
      headers: {
        "x-access-token": INTERAKT_TOKEN,
        "x-waba-id": secrets.wabaId,
        "Content-Type": "application/json",
      },
      params, // <-- Add query params for pagination
    });

    const responseBody = response.data;

    return res.json({
      success: responseBody.success,
      data: response.data,
    });

  } catch (err) {
    const errData = err.response?.data || err.message;
    logger.error("INTERAKT GET ERROR:", errData);

    return res.status(500).json({
      success: false,
      message: errData,
    });
  }
});

const getApprovedTemplates = onRequest({ cors: true }, async (req, res) => {
  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "GET") return res.status(405).json({ success: false, message: "Method not allowed" });

  try {
    const { clientId } = req.query;
    const secrets = await getSecrets(clientId);
    const response = await axios.get(`${BASE_URL}/${secrets.wabaId}/message_templates`, {
      headers: {
        "x-access-token": INTERAKT_TOKEN,
        "x-waba-id": secrets.wabaId,
        "Content-Type": "application/json",
      },
      params: { fields: 'name,category', status: 'APPROVED' }
    });

    const approvedTemplates = response.data.data;

    return res.json({ success: true, data: approvedTemplates });
  } catch (err) {
    logger.error("Error fetching approved templates:", err);
    return res.status(500).json({ success: false, message: "Internal server error" });
  }
});

const getApprovedMediaTemplates = onRequest({ cors: true }, async (req, res) => {
  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "GET") return res.status(405).json({ success: false, message: "Method not allowed" });

  try {
    const { clientId } = req.query;
    const secrets = await getSecrets(clientId);

    const response = await axios.get(`${BASE_URL}/${secrets.wabaId}/message_templates`, {
      headers: {
        "x-access-token": INTERAKT_TOKEN,
        "x-waba-id": secrets.wabaId,
        "Content-Type": "application/json",
      },
      params: { fields: 'name,category', status: 'APPROVED' },
    });
    const approvedTemplates = response.data.data;

    // Fetch "Text & Media" template IDs from Firestore
    const mediaTemplatesSnap = await db.collection("templates").doc(clientId).collection("data").where("type", "==", "Text & Media").get();
    // Use a Set for O(1) lookup complexity
    const mediaTemplatesIds = new Set(mediaTemplatesSnap.docs.filter(doc => doc.data().components[0].format === "IMAGE").map(doc => doc.id));

    // Filter approved templates efficiently
    const approvedMediaTemplates = approvedTemplates.filter(template => mediaTemplatesIds.has(template.id));

    return res.json({ success: true, data: approvedMediaTemplates });
  } catch (err) {
    logger.error("Error fetching approved templates:", err);
    return res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// ---------------------------------------------------------------
// ❌ DELETE Interakt Template (by NAME)
// ---------------------------------------------------------------
const deleteInteraktTemplate = onRequest({ cors: true }, async (req, res) => {
  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST")
    return res.status(405).json({ success: false, message: "Method not allowed" });

  try {
    const name = req.query.name || req.body.name;
    const clientId = req.query.clientId || req.body.clientId;
    const secrets = await getSecrets(clientId);

    if (!name) {
      return res.status(400).json({
        success: false,
        message: "Missing template name",
      });
    }

    const deleteUrl = `${BASE_URL}/${secrets.wabaId}/message_templates?name=${encodeURIComponent(name)}`;

    const response = await axios.delete(deleteUrl, {
      headers: {
        "x-access-token": INTERAKT_TOKEN,
        "x-waba-id": secrets.wabaId,
        "Content-Type": "application/json",
      },
    });

    return res.json({
      success: true,
      message: "Template deleted successfully",
      data: response.data,
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: err.response?.data || err.message,
    });
  }
});



// ---------------------------------------------------------------
//  Upload Media Interakt Template 
// ---------------------------------------------------------------
const uploadMediaToInterakt = onRequest({ cors: true }, async (req, res) => {
  if (req.method === "OPTIONS") return res.status(200).end();

  try {
    if (!req.headers["content-type"]?.includes("multipart/form-data")) {
      return res.status(400).json({
        success: false,
        message: "Send as multipart/form-data with file"
      });
    }

    const busboy = Busboy({ headers: req.headers });

    const fields = {};
    let fileBuffer = null;
    let fileName = "";
    let mimeType = "";

    await new Promise((resolve, reject) => {
      busboy.on("field", (fieldname, val) => {
        fields[fieldname] = val;
      });

      busboy.on("file", (field, file, info) => {
        const chunks = [];
        fileName = info.filename;
        mimeType = info.mimeType;

        file.on("data", (d) => chunks.push(d));
        file.on("end", () => {
          fileBuffer = Buffer.concat(chunks);
        });
      });

      busboy.on("finish", resolve);
      busboy.on("error", reject);

      busboy.end(req.rawBody);
    });

    if (!fileBuffer) {
      return res.status(400).json({
        success: false,
        message: "File is missing"
      });
    }

    const secrets = await getSecrets(fields.clientId);
    const mediaHandle = await createMediaHandle(secrets, fileBuffer, fileName, mimeType);

    // 🔥 KEEP SAME FORMAT AS OLD API
    return res.status(200).json({
      success: true,
      media_handle_id: mediaHandle
    });

  } catch (err) {
    console.error("UPLOAD ERROR:", err.response?.data || err.message);

    return res.status(500).json({
      success: false,
      message: err.response?.data || err.message
    });
  }
});

const uploadBroadcastMedia = onRequest({ cors: true }, async (req, res) => {
  if (req.method === "OPTIONS") return res.status(200).end();

  try {
    if (!req.headers["content-type"]?.includes("multipart/form-data")) {
      return res.status(400).json({
        success: false,
        message: "Please send as multipart/form-data with a 'file' field."
      });
    }
    logger.info("Starting broadcast media upload...");
    const busboy = Busboy({ headers: req.headers });

    const fields = {};
    let broadcastMediaBuffer = null;
    let broadcastMediaName = "";
    let broadcastMediaMime = "";

    await new Promise((resolve, reject) => {
      busboy.on("field", (fieldname, val) => {
        fields[fieldname] = val;
      });

      busboy.on("file", (fieldName, file, fileInfo) => {
        const chunks = [];
        logger.info(`Receiving file: ${fileInfo.filename} (${fileInfo.mimeType})`);
        broadcastMediaName = fileInfo.filename;
        broadcastMediaMime = fileInfo.mimeType;

        file.on("data", (d) => chunks.push(d));
        file.on("end", () => {
          broadcastMediaBuffer = Buffer.concat(chunks);
        });
      });

      busboy.on("finish", resolve);
      busboy.on("error", reject);

      busboy.end(req.rawBody);
    });

    if (!broadcastMediaBuffer) {
      return res.status(400).json({
        success: false,
        message: "No file found in request."
      });
    }

    const secrets = await getSecrets(fields.clientId);
    const mediaId = await createMediaId(secrets, broadcastMediaBuffer, broadcastMediaName, broadcastMediaMime);

    return res.status(200).json({
      success: true,
      media_id:
        mediaId
    });

  } catch (err) {
    console.error("Broadcast Media Upload Error:", err.response?.data || err.message);

    return res.status(500).json({
      success: false,
      message: err.response?.data || err.message,
    });
  }
});

async function createMediaHandle(secrets, fileBuffer, fileName, mimeType) {
  try {
    // Build FormData exactly like cURL
    const form = new FormData();
    form.append("file", fileBuffer, {
      filename: fileName,
      contentType: mimeType
    });
    form.append("messaging_product", "whatsapp");
    form.append("type", mimeType);

    // Send to Interakt
    const response = await axios.post(`${BASE_URL}/${secrets.phoneNumberId}/media_handle`, form, {
      headers: {
        "x-access-token": INTERAKT_TOKEN,
        "x-waba-id": secrets.wabaId,
        ...form.getHeaders()
      },
      maxBodyLength: Infinity,
      maxContentLength: Infinity
    });

    return response.data?.h;
  } catch (err) {
    logger.error("Error in createMediaHandle:", err.response?.data || err.message);
    throw err;
  }
}

async function createMediaId(secrets, fileBuffer, fileName, mimeType) {
  try {
    const form = new FormData();
    form.append("file", fileBuffer, {
      filename: fileName,
      contentType: mimeType
    });
    form.append("messaging_product", "whatsapp");
    form.append("type", mimeType);

    logger.info(`Uploading media to Interakt: ${fileName}...`);
    const response = await axios.post(`${BASE_URL}/${secrets.phoneNumberId}/media`, form, {
      headers: {
        "x-access-token": INTERAKT_TOKEN,
        "x-waba-id": secrets.wabaId,
        ...form.getHeaders()
      },
      maxBodyLength: Infinity,
      maxContentLength: Infinity
    });

    return response.data.id;
  } catch (err) {
    logger.error("Error in createMediaId:", err.response?.data || err.message);
    throw err;
  }
}

module.exports = {
  createInteraktTemplate,
  getInteraktTemplates,
  getApprovedTemplates,
  getApprovedMediaTemplates,
  deleteInteraktTemplate,
  uploadMediaToInterakt,
  uploadBroadcastMedia,
  createMediaHandle,
  createMediaId
};
