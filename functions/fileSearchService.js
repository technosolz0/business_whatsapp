const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const Busboy = require("busboy");
const axios = require("axios");
const { GoogleGenAI } = require("@google/genai");

const STORE_ID = process.env.STORE_ID;
const QNA_STORE_ID = process.env.QNA_STORE_ID;

// Initialize Gemini Client
const apiKey = process.env.GOOGLE_API_KEY;
const client = new GoogleGenAI({ apiKey });

/**
 * Helper to get the target store ID based on a boolean flag.
 * @param {boolean|string} isQnA - Flag to indicate if QnA store should be used.
 * @returns {string} - The selected store ID.
 */
const getTargetStoreId = (isQnA) => {
    return (isQnA === "true" || isQnA === true) ? QNA_STORE_ID : STORE_ID;
};

/**
 * Endpoint to upload files to Google Gen AI File Search Store.
 * 
 * This endpoint accepts `multipart/form-data` requests containing:
 * - `files`: A single file to upload.
 */
const uploadToFileSearchStore = onRequest(async (req, res) => {
    // Set CORS headers to allow requests from any origin
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Headers", "*");

    // Handle preflight OPTIONS requests
    if (req.method === "OPTIONS") {
        return res.status(200).end();
    }

    // Check if the request is a POST request
    if (req.method !== "POST") {
        return res.status(405).json({
            success: false,
            message: "Only POST requests are allowed"
        });
    }

    try {
        const { fields, files } = await parseMultipart(req);

        const targetStoreId = getTargetStoreId(fields.isQnA);

        if (!targetStoreId) {
            return res.status(400).json({
                success: false,
                message: "Target store ID not configured"
            });
        }

        if (!files || files.length === 0) {
            return res.status(400).json({
                success: false,
                message: "No files uploaded"
            });
        }

        const apiKey = process.env.GOOGLE_API_KEY;
        if (!apiKey) {
            logger.error("GOOGLE_API_KEY is missing in environment variables.");
            return res.status(500).json({
                success: false,
                message: "Server configuration error: API Key missing"
            });
        }

        // Upload all files to the selected Google File Search Store
        const uploadPromises = files.map(file =>
            uploadToFileSearchStoreHelper(
                targetStoreId,
                file.buffer,
                file.mimeType,
                file.filename,
                fields.description
            )
        );

        const results = await Promise.all(uploadPromises);
        const ids = results.map(r => r.response.documentName);

        return res.json({
            success: true,
            data: {
                ids: ids
            }
        });

    } catch (error) {
        logger.error("Unexpected error in uploadToFileSearchStore:", error);
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * Endpoint to delete a file from Google Gen AI File Search Store.
 * 
 * Accepts JSON body:
 * - `id`: The resource name of the document to delete (e.g., "corpora/.../documents/...").
 */
const deleteFromFileSearchStore = onRequest(async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Headers", "*");

    if (req.method === "OPTIONS") {
        return res.status(200).end();
    }

    if (req.method !== "POST") {
        return res.status(405).json({ success: false, message: "Only POST requests are allowed" });
    }

    try {
        const name = req.body.id || req.query.id;

        if (!name) {
            return res.status(400).json({ success: false, message: "Missing required parameter: id" });
        }

        logger.info(`Deleting document: ${name}`);
        await client.fileSearchStores.documents.delete({ name: name, config: { force: true } });

        return res.json({
            success: true,
            message: `Document ${name} deleted successfully.`
        });

    } catch (error) {
        logger.error("Error in deleteFromFileSearchStore:", error);
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * Endpoint to list all documents in the Google Gen AI File Search Store.
 */
const listDocumentsFromFileSearchStore = onRequest({ cors: true }, async (req, res) => {
    if (req.method === "OPTIONS") {
        return res.status(200).end();
    }
    // Allow GET or POST
    if (req.method !== "GET") {
        return res.status(405).json({
            success: false,
            message: "Only GET requests are allowed"
        });
    }

    try {
        const isQnA = req.query.isQnA || req.body.isQnA;
        const targetStoreId = getTargetStoreId(isQnA);

        if (!targetStoreId) {
            return res.status(400).json({
                success: false,
                message: "Target store ID is not configured"
            });
        }

        logger.info(`Listing documents for store: ${targetStoreId}`);
        const response = await client.fileSearchStores.documents.list({
            parent: targetStoreId
        });

        const data = [];
        for (let i = 0; i < response.pageLength; i++) {
            const doc = response.getItem(i);
            const descriptionMetaData = doc.customMetadata?.find(m => m.key === "description");
            data.push({
                id: doc.name,
                fileName: doc.displayName,
                fileMimeType: doc.mimeType,
                description: descriptionMetaData ? descriptionMetaData.stringValue : "",
                dateUploaded: doc.createTime,
            });
        }

        return res.json({
            success: true,
            data: data
        });

    } catch (error) {
        logger.error("Error in listFileSearchStoreDocuments:", error);
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * Endpoint to update a file in Google Gen AI File Search Store.
 * Since files cannot be updated directly, this deletes the old file and uploads the new one.
 * 
 * Accepts `multipart/form-data`:
 * - `files`: The new file.
 * - `id`: The resource name of the existing document to delete.
 */
const updateInFileSearchStore = onRequest(async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Headers", "*");

    if (req.method === "OPTIONS") return res.status(200).end();
    if (req.method !== "POST") return res.status(405).json({ success: false, message: "Only POST requests are allowed" });

    try {
        const { fields, files } = await parseMultipart(req);

        const name = fields.id;
        const uploadedFile = files[0];
        const targetStoreId = getTargetStoreId(fields.isQnA);

        if (!name) {
            return res.status(400).json({ success: false, message: "Missing required fields: id" });
        }

        if (!uploadedFile) {
            return res.status(400).json({ success: false, message: "No new file uploaded" });
        }

        // 1. Delete the old document (name includes store path, so it's store-independent if full name is provided)
        try {
            logger.info(`Deleting old document: ${name}`);
            await client.fileSearchStores.documents.delete({ name: name, config: { force: true } });
        } catch (postError) {
            logger.warn(`Failed to delete old document ${name}, proceeding with upload. Error: ${postError.message}`);
        }

        // 2. Upload the new file
        const result = await uploadToFileSearchStoreHelper(
            targetStoreId,
            uploadedFile.buffer,
            uploadedFile.mimeType,
            uploadedFile.filename,
            fields.description
        );

        return res.json({
            success: true,
            message: "File updated successfully (old deleted, new uploaded)",
            data: {
                id: result.response.documentName
            }
        });

    } catch (error) {
        logger.error("Error in updateFileInFileSearchStore:", error);
        return res.status(500).json({ success: false, message: error.message });
    }
});


/**
 * Helper to parse multipart/form-data requests.
 */
function parseMultipart(req) {
    return new Promise((resolve, reject) => {
        const busboy = Busboy({ headers: req.headers });
        const fields = {};
        const files = [];
        const filePromises = [];

        busboy.on("field", (fieldname, val) => {
            fields[fieldname] = val;
        });

        busboy.on("file", (fieldname, file, info) => {
            const { filename, mimeType } = info;
            const chunks = [];
            file.on("data", (data) => chunks.push(data));

            const p = new Promise((resolveFile, rejectFile) => {
                file.on("end", () => {
                    files.push({
                        filename,
                        mimeType,
                        buffer: Buffer.concat(chunks)
                    });
                    resolveFile();
                });
                file.on("error", rejectFile);
            });
            filePromises.push(p);
        });

        busboy.on("finish", async () => {
            try {
                await Promise.all(filePromises);
                resolve({ fields, files });
            } catch (e) {
                reject(e);
            }
        });

        busboy.on("error", reject);
        busboy.end(req.rawBody);
    });
}

/**
 * Helper function to upload a single file to Google Gen AI File Search Store.
 * 
 * @param {Buffer} fileBuffer - The file content as a buffer.
 * @param {string} mimeType - The MIME type of the file.
 * @param {string} displayName - The display name for the file in the store.
 * @param {string} description - The description for the file.
 * @returns {Promise<Object>} - The response data from the Google API.
 */
async function uploadToFileSearchStoreHelper(storeId, fileBuffer, mimeType, displayName, description) {
    try {
        const config = {
            displayName: displayName
        };

        if (description) {
            config.customMetadata = [
                {
                    key: "description",
                    stringValue: description
                }
            ];
        }

        const response = await client.fileSearchStores.uploadToFileSearchStore({
            fileSearchStoreName: storeId,
            file: new Blob([fileBuffer], { type: mimeType }),
            config: config
        });

        return response;
    } catch (error) {
        logger.error(`Error uploading file ${displayName} to store ${storeId}:`, error.response?.data || error.message);
        throw new Error(`Failed to upload ${displayName}: ${JSON.stringify(error.response?.data || error.message)}`);
    }
}

module.exports = {
    uploadToFileSearchStore,
    deleteFromFileSearchStore,
    listDocumentsFromFileSearchStore,
    updateInFileSearchStore,
    parseMultipart
};