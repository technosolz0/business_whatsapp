const admin = require("firebase-admin");

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();

async function getSecrets(clientId) {
    const data = (await db.collection("clients").doc(clientId).get()).data();
    return {
        wabaId: data.wabaId,
        phoneNumberId: data.phoneNumberId,
        phoneNumber: data.phoneNumber,
        webhookVerifyToken: data.webhookVerifyToken,
        storeId: data.storeId,
        qnaStoreId: data.qnaStoreId,
        googleApiKey: data.googleApiKey
    };
}

module.exports = {
    getSecrets
};
