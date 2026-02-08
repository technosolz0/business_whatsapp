const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();

const migrateCollectionData = onRequest({ cors: true }, async (req, res) => {
    // Handle OPTIONS for CORS
    if (req.method === "OPTIONS") {
        return res.status(200).send();
    }

    try {
        // 1. Extract params from body or query
        const clientId = req.body.clientId || req.query.clientId;
        const collectionPath = req.body.collectionPath || req.query.collectionPath;

        if (!clientId || !collectionPath) {
            return res.status(400).json({
                success: false,
                message: "Missing required parameters: clientId, collectionPath",
            });
        }

        logger.info(`Starting migration for collection: ${collectionPath} to clientId: ${clientId}`);

        // 2. Fetch all docs from the source collection
        const sourceCollectionRef = db.collection(collectionPath);
        const snapshot = await sourceCollectionRef.get();

        if (snapshot.empty) {
            return res.status(200).json({
                success: true,
                message: `No documents found in ${collectionPath}`,
                count: 0
            });
        }

        const batchSize = 500;
        let batch = db.batch();
        let count = 0;
        let totalMigrated = 0;

        // Helper to add operations to batch and commit if limit reached
        const addToBatch = async (ref, data) => {
            batch.set(ref, data);
            count++;

            // Commit batch if limit reached
            if (count >= batchSize) {
                await batch.commit();
                totalMigrated += count;
                logger.info(`Migrated ${totalMigrated} documents...`);
                batch = db.batch(); // Reset batch
                count = 0;
            }
        };

        // 3. Iterate and set data in the target location
        // Target: db.collection(collectionPath).doc(clientId).collection("data")
        const targetCollectionRef = sourceCollectionRef.doc(clientId).collection("data");

        for (const doc of snapshot.docs) {
            const docData = doc.data();
            const docId = doc.id;

            // Create a reference to the new document location
            const targetDocRef = targetCollectionRef.doc(docId);

            // Add main document to batch
            await addToBatch(targetDocRef, docData);

            // Check for and migrate subcollections
            const subcollections = await doc.ref.listCollections();
            for (const subcol of subcollections) {
                const subSnapshot = await subcol.get();
                if (!subSnapshot.empty) {
                    for (const subDoc of subSnapshot.docs) {
                        const subTargetRef = targetDocRef.collection(subcol.id).doc(subDoc.id);
                        await addToBatch(subTargetRef, subDoc.data());
                    }
                }
            }
        }

        // Commit any remaining documents
        if (count > 0) {
            await batch.commit();
            totalMigrated += count;
        }

        logger.info(`Migration completed. Total documents migrated: ${totalMigrated}`);

        return res.status(200).json({
            success: true,
            message: "Migration completed successfully",
            collection: collectionPath,
            clientId: clientId,
            migratedCount: totalMigrated,
        });

    } catch (error) {
        logger.error("Migration Error:", error);
        return res.status(500).json({
            success: false,
            message: error.message,
        });
    }
});

module.exports = {
    migrateCollectionData,
};
