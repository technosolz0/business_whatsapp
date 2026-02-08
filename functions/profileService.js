const axios = require("axios");
const logger = require("firebase-functions/logger");
const { onRequest } = require("firebase-functions/v2/https");
const { parseMultipart } = require("./fileSearchService");
const { createMediaHandle } = require("./templateHandler");
const { getSecrets } = require("./utils");
require("dotenv").config();

const BASE_URL = process.env.BASE_URL;
const INTERAKT_TOKEN = process.env.INTERAKT_TOKEN;

const getWhatsAppBusinessProfile = onRequest({ cors: true }, async (req, res) => {
    if (req.method !== "GET") {
        return res.status(405).json({
            success: false,
            message: "Only GET requests are allowed"
        });
    }

    const secrets = await getSecrets(req.query.clientId);

    try {
        const response = await axios.get(`${BASE_URL}/${secrets.phoneNumberId}/whatsapp_business_profile?fields=about,address,description,email,profile_picture_url,websites,vertical`, {
            headers: {
                "x-access-token": INTERAKT_TOKEN,
                "x-waba-id": secrets.wabaId,
                "Content-Type": "application/json",
            },
        });

        // Safe access to data
        const profileData = response.data?.data?.[0] || response.data;
        res.status(200).json({
            success: true,
            data: [profileData]
        });
    } catch (error) {
        const errorData = error.response ? error.response.data : error.message;
        logger.error("Error getting WhatsApp Business Profile:", errorData);
        res.status(500).json({
            success: false,
            message: "Failed to fetch WhatsApp profile",
            error: errorData
        });
    }
});

const updateWhatsAppBusinessProfile = onRequest({ cors: true }, async (req, res) => {
    if (req.method !== "POST") {
        return res.status(405).json({
            success: false,
            message: "Only POST requests are allowed"
        });
    }

    try {
        const { fields, files } = await parseMultipart(req);
        let mediaHandle = null;
        const uploadedFile = files?.[0]; // Guard against undefined files

        if (uploadedFile) {
            mediaHandle = await createMediaHandle(uploadedFile.buffer, uploadedFile.mimeType, uploadedFile.filename);
        }

        const payload = {
            ...fields,
            profile_picture_handle: mediaHandle
        };

        const result = await updateWhatsAppBusinessProfileHelper(payload);
        res.status(200).json(result);
    } catch (error) {
        const errorData = error.response ? error.response.data : error.message;
        logger.error("Error updating WhatsApp Business Profile:", errorData);
        res.status(500).json({
            success: false,
            message: "Failed to update WhatsApp profile",
            error: errorData
        });
    }
});


/**
 * Updates the WhatsApp Business Profile.
 * 
 * @param {Object} profileData - The profile data to update.
 * @param {string} profileData.about - "Hey there! I am using WhatsApp."
 * @param {string} profileData.address - Address string.
 * @param {string} profileData.description - Business description.
 * @param {string} profileData.vertical - Business vertical (e.g., "OTHER").
 * @param {string} profileData.email - Business email.
 * @param {string[]} profileData.websites - List of website URLs.
 * @param {string} profileData.profile_picture_handle - Media handle for Profile Picture.
 * @returns {Promise<Object>} - The API response data.
 */
async function updateWhatsAppBusinessProfileHelper(profileData) {

    const secrets = await getSecrets(profileData.clientId);

    const URL = `${BASE_URL}/${secrets.phoneNumberId}/whatsapp_business_profile`;

    logger.info(`Updating WhatsApp Business Profile for WABA ID: ${secrets.wabaId}...`);

    try {
        const response = await axios.post(URL, {
            messaging_product: "whatsapp",
            ...profileData
        }, {
            headers: {
                "x-access-token": INTERAKT_TOKEN,
                "x-waba-id": secrets.wabaId,
                "Content-Type": "application/json",
            },
        });

        logger.info("WhatsApp Business Profile updated successfully.");
        return response.data;
    } catch (error) {
        const errorData = error.response ? error.response.data : error.message;
        logger.error("Error updating WhatsApp Business Profile:", errorData);
        throw new Error(JSON.stringify(errorData));
    }
}

module.exports = {
    getWhatsAppBusinessProfile,
    updateWhatsAppBusinessProfile
};