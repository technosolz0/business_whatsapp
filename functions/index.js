const { setGlobalOptions } = require("firebase-functions");
require("dotenv").config();
const admin = require("firebase-admin");

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

setGlobalOptions({ maxInstances: 10 });

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
  ...require("./profileService"),

  // Migration Service ================================================
  ...require("./migrationHandler")
};