const { setGlobalOptions } = require("firebase-functions");
const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const axios = require("axios");
require("dotenv").config();
const admin = require("firebase-admin");
const { PubSub } = require('@google-cloud/pubsub');

admin.initializeApp();

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




module.exports = {
  // Wehook ============================================================
  ...require("./webhookHandler"),

  // Shubhangi ============================================================
  ...require("./templateHandler"),

  // Ayman ============================================================
  ...require("./broadcastHandler"),

  // Aamir ============================================================
  ...require("./chatHandler"),

  // File Search Service ==============================================
  ...require("./fileSearchService"),

  // Daily Schedulers =================================================
  ...require("./dailySchedulers"),

  // Profile Service ==================================================
  ...require("./profileService")
};