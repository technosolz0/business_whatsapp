const { GoogleGenAI } = require("@google/genai");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const axios = require("axios");

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();

// Initialize Gemini Client
const apiKey = process.env.GOOGLE_API_KEY;
const client = new GoogleGenAI({ apiKey });

const fallbackPhrase = "We couldn't find that information. Would you like to schedule a call with a representative?";
const systemPrompt = `You are the AIS Virtual Assistant. 
CRITICAL: You have access to a Knowledge Base via the 'fileSearch' tool and a 'scheduleCall' tool.
Rules:
- 1st PERSON PLURAL TONE: Always speak in the 1st person plural (e.g., "We", "us", "our"). Represent the business/team.
- FORMATTING: Use WhatsApp-style formatting:
  - *Bold* for important terms or headers.
  - _Italics_ for emphasis.
  - Use bullet points for lists.
- READABILITY: Break long responses into concise bullet points.
- SCHEDULE CALL: 
  - If a user mentions wanting to speak to a representative or provides a date/time, use 'scheduleCall'.
  - If a user refuses the call (e.g., "No", "Not now"), politely acknowledge ("Okay, let us know if you need anything else.") and DO NOT use the fallback phrase.
- ALWAYS SEARCH: Search the Knowledge Base for every query.
- STRICTLY GROUNDED: Answer ONLY using the Knowledge Base.
- MISSING INFO:
  - If the answer is NOT in the documents, you MUST respond with EXACTLY this phrase and nothing else: "${fallbackPhrase}"
  - Do not try to rephrase it.
- Tone: Professional, helpful, and friendly.`;

/**
 * Generate content using Google Gemini with File Search tool.
 * 
 * @param {string} prompt - The text prompt for the model.
 * @param {string[]} storeIds - The resource names of the File Search Store (e.g., "fileSearchStores/...").
 * @param {string} modelName - The model to use.
 * @param {Object} config - Optional configuration for generation.
 * @param {string} [sessionId] - Unique ID for the conversation (e.g., contactId).
 * @param {number} [contextWindow=10] - Number of previous messages to remember.
 * @returns {Promise<string>} - The generated text response.
 */
async function generateContentWithFileSearch(prompt, storeIds, modelName = "gemini-2.5-flash-lite", config = {}, sessionId = null, contextWindow = 10) {
    if (!apiKey) {
        throw new Error("GOOGLE_API_KEY is not set in environment variables.");
    }

    try {
        let history = [];
        if (sessionId) {
            history = await getChatHistory(sessionId, contextWindow);
        }

        // Format contents: history + current prompt
        const contents = [
            ...history,
            { role: "user", parts: [{ text: prompt }] }
        ];

        logger.info(`Generating content with file search and tool support... sessionId: ${sessionId}, contextWindow: ${contextWindow}, prompt: ${prompt}`);

        const result = await client.models.generateContent({
            model: modelName,
            contents: contents,
            config: {
                tools: [
                    {
                        fileSearch: {
                            fileSearchStoreNames: storeIds
                        }
                    },
                    {
                        functionDeclarations: [
                            {
                                name: "scheduleCall",
                                description: "Schedule a call with a business representative when a user provides a date and time.",
                                parameters: {
                                    type: "OBJECT",
                                    properties: {
                                        dateTime: {
                                            type: "STRING",
                                            description: "The date and time the user wants to schedule the call for (e.g., 'tomorrow at 3pm', '2025-12-25 10:00')."
                                        },
                                        reason: {
                                            type: "STRING",
                                            description: "The reason for the call or any specific topic mentioned by the user."
                                        }
                                    },
                                    required: ["dateTime"]
                                }
                            }
                        ]
                    }
                ],
                maxOutputTokens: config.maxOutputTokens || 500,
                systemInstruction: systemPrompt
            }
        });

        let responseText = result.text;

        // Handle potential function calls
        const functionCalls = result.functionCalls;
        if (functionCalls && functionCalls.length > 0) {
            for (const call of functionCalls) {
                if (call.name === "scheduleCall") {
                    const { dateTime, reason } = call.args;
                    logger.info(`Tool Call: scheduleCall detected. DateTime: ${dateTime}, Reason: ${reason}`);

                    // Notify sales team
                    await notifySalesTeam(sessionId, dateTime, reason);

                    // We can either return a confirmation or continue the generation
                    // For simplicity, we'll append a confirmation to the response if text is empty
                    if (!responseText) {
                        responseText = `Great! I've noted down your request for a call on ${dateTime}. Our team will get back to you shortly.`;
                    }
                }
            }
        }

        // Check for unanswered question
        if (responseText && responseText.includes(fallbackPhrase)) {
            await logUnansweredQuestion(sessionId, prompt);
        }

        return responseText;

    } catch (error) {
        logger.error("Error generating content with file search:", error);
        throw error;
    }
}

/**
 * Retrieves chat history from the existing 'chats' collection in Firestore.
 */
async function getChatHistory(sessionId, limit) {
    try {
        const historyRef = db.collection("chats")
            .doc(sessionId)
            .collection("messages")
            .where("messageType", "==", "text")
            .orderBy("timestamp", "desc")
            .limit(limit);

        const snapshot = await historyRef.get();
        const history = [];

        snapshot.forEach(doc => {
            const data = doc.data();
            // Map roles based on isFromMe: true -> model, false -> user
            const role = data.isFromMe ? "model" : "user";

            // unshift to keep chronological order (last messages first in Gemini contents)
            history.unshift({
                role: role,
                parts: [{ text: data.content || "" }]
            });
        });

        return history;
    } catch (error) {
        logger.error(`Error fetching history for chat session ${sessionId}:`, error);
        return [];
    }
}

/**
 * Notifies the sales team about a call request.
 */
async function notifySalesTeam(contactId, dateTime, reason) {
    try {
        const salesPhone = process.env.SALES_TEAM_WHATSAPP;
        if (!salesPhone) {
            logger.warn("SALES_TEAM_WHATSAPP not set in .env. Skipping WhatsApp notification.");
            return;
        }

        // Fetch contact details for better notification
        const contactDoc = await db.collection("contacts").doc(contactId).get();
        let contactInfo = contactId;
        if (contactDoc.exists) {
            const data = contactDoc.data();
            contactInfo = `${data.fName || ""} ${data.lName || ""} (${data.phoneNumber || contactId})`.trim();
        }

        const notificationText = `🚀 *New Call Scheduled!*\n\n*Contact:* ${contactInfo}\n*Time:* ${dateTime}\n*Topic:* ${reason || "Not specified"}\n\nPlease reach out to the customer at the scheduled time.`;

        // Send via WhatsApp Interakt API
        const PHONENUMBERID = process.env.PHONENUMBERID;
        const SEND_MESSAGE_URL = `https://amped-express.interakt.ai/api/v24.0/${PHONENUMBERID}/messages`;
        const TOKEN = process.env.INTERAKT_TOKEN;
        const WABA_ID = process.env.WABA_ID;

        await axios.post(SEND_MESSAGE_URL, {
            messaging_product: "whatsapp",
            to: salesPhone.replace(/[+\s-]/g, ""),
            type: "text",
            text: { body: notificationText }
        }, {
            headers: {
                "x-access-token": TOKEN,
                "x-waba-id": WABA_ID,
                "Content-Type": "application/json",
            },
        });

        logger.info(`Sales team notified about call for contact ${contactId}`);

    } catch (error) {
        logger.error("Error notifying sales team:", error.response?.data || error.message);
    }
}

/**
 * Logs unanswered questions to a separate collection.
 */
async function logUnansweredQuestion(contactId, question) {
    try {
        await db.collection("unanswered_questions").add({
            contactId: contactId,
            question: question,
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });
        logger.info(`Unanswered question logged for contact ${contactId}`);
    } catch (error) {
        logger.error("Error logging unanswered question:", error);
    }
}

// Export the function locally for use in other files
module.exports = {
    generateContentWithFileSearch
};

// Optional: Export as a callable Cloud Function if needed directly (commented out by default)
/*
exports.generateContent = onRequest(async (req, res) => {
    // ... implementation ...
});
*/