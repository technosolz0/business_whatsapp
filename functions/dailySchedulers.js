const { onRequest } = require("firebase-functions/v2/https");
const { CloudSchedulerClient } = require('@google-cloud/scheduler');
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const sharp = require("sharp");
const { sendWhatsAppTemplateMessageHelper } = require("./broadcastHandler");
const { createMediaId } = require("./templateHandler");
// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
const schedulerClient = new CloudSchedulerClient();
const PROJECT_ID = process.env.PROJECT_ID;
const REGION = process.env.REGION;

exports.createMilestoneCronJob = onRequest({ cors: true }, async (req, res) => {
    try {

        if (req.method === "OPTIONS") {
            return res.status(200).send("OK");
        }

        if (req.method !== "POST") {
            return res.status(405).json({
                success: false,
                message: "Method not allowed.",
            });
        }
        const { schedulerId, scheduleTime } = req.body;

        logger.info(`Scheduler ID: ${schedulerId}, Schedule Time: ${scheduleTime}`);

        const cronExpression = convertTimeToCron(scheduleTime);
        await schedulerClient.createJob({
            parent: schedulerClient.locationPath(PROJECT_ID, REGION),
            job: {
                name: schedulerClient.jobPath(PROJECT_ID, REGION, schedulerId),
                schedule: cronExpression,
                timeZone: "Asia/Kolkata", // Adjust time zone as needed, using user's evident locale (Offset +05:30)
                retryConfig: {
                    retryCount: 3,
                },
                httpTarget: {
                    uri: `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/sendMilestoneMessages`,
                    httpMethod: "POST",
                    headers: {
                        "Content-Type": "application/json",
                    },
                    body: Buffer.from(JSON.stringify({ schedulerId })).toString("base64"),
                },
            }
        });

        logger.info("Scheduler created successfully.");

        res.json({
            success: true,
            message: "Scheduler created successfully.",
        });
    } catch (error) {
        logger.error("Error creating Scheduler:", error);
        res.status(500).json({
            success: false,
            message: "Error creating Scheduler.",
        });
    }
});

exports.pauseMilestoneCronJob = onRequest({ cors: true }, async (req, res) => {
    try {
        if (req.method === "OPTIONS") {
            return res.status(200).send("OK");
        }

        if (req.method !== "POST") {
            return res.status(405).json({
                success: false,
                message: "Method not allowed.",
            });
        }
        const { clientId, schedulerId } = req.body;
        const name = schedulerClient.jobPath(PROJECT_ID, REGION, schedulerId);

        //pause the job
        await schedulerClient.pauseJob({
            name: name,
        });

        //update the scheduler status
        await db.collection("milestone_schedulars").doc(clientId).collection("data").doc(schedulerId).update({
            status: "paused",
        });

        logger.info("Scheduler paused successfully.");

        res.status(200).json({
            success: true,
            message: "Scheduler paused successfully.",
        });
    } catch (error) {
        logger.error("Error pausing Scheduler:", error);
        res.status(500).json({
            success: false,
            message: "Error pausing Scheduler.",
        });
    }
});

exports.resumeMilestoneCronJob = onRequest({ cors: true }, async (req, res) => {
    try {
        if (req.method === "OPTIONS") {
            return res.status(200).send("OK");
        }

        if (req.method !== "POST") {
            return res.status(405).json({
                success: false,
                message: "Method not allowed.",
            });
        }
        const { clientId, schedulerId } = req.body;
        const name = schedulerClient.jobPath(PROJECT_ID, REGION, schedulerId);

        //resume the job
        await schedulerClient.resumeJob({
            name: name,
        });

        //update the scheduler status
        await db.collection("milestone_schedulars").doc(clientId).collection("data").doc(schedulerId).update({
            status: "active",
        });

        logger.info("Scheduler resumed successfully.");

        res.status(200).json({
            success: true,
            message: "Scheduler resumed successfully.",
        });
    } catch (error) {
        logger.error("Error resuming Scheduler:", error);
        res.status(500).json({
            success: false,
            message: "Error resuming Scheduler.",
        });
    }
});

exports.deleteMilestoneCronJob = onRequest({ cors: true }, async (req, res) => {
    try {
        if (req.method === "OPTIONS") {
            return res.status(200).send("OK");
        }

        if (req.method !== "POST") {
            return res.status(405).json({
                success: false,
                message: "Method not allowed.",
            });
        }
        const { clientId, schedulerId } = req.body;
        const name = schedulerClient.jobPath(PROJECT_ID, REGION, schedulerId);

        //pause the job
        // await schedulerClient.pauseJob({
        //     name: name,
        // });

        //delete the job
        await schedulerClient.deleteJob({
            name: name,
        });

        //delete the scheduler
        await db.collection("milestone_schedulars").doc(clientId).collection("data").doc(schedulerId).delete();

        logger.info("Scheduler deleted successfully.");

        res.status(200).json({
            success: true,
            message: "Scheduler deleted successfully.",
        });
    } catch (error) {
        logger.error("Error deleting Scheduler:", error);
        res.status(500).json({
            success: false,
            message: "Error deleting Scheduler.",
        });
    }
});

exports.updateMilestoneCronJob = onRequest({ cors: true }, async (req, res) => {
    try {
        if (req.method === "OPTIONS") {
            return res.status(200).send("OK");
        }

        if (req.method !== "POST") {
            return res.status(405).json({
                success: false,
                message: "Method not allowed.",
            });
        }
        const { schedulerId, scheduleTime } = req.body;

        logger.info(`Updating Scheduler ID: ${schedulerId}, New Time: ${scheduleTime}`);

        // Convert to cron
        const cronExpression = convertTimeToCron(scheduleTime);
        const name = schedulerClient.jobPath(PROJECT_ID, REGION, schedulerId);

        // Update Job
        await schedulerClient.updateJob({
            job: {
                name: name,
                schedule: cronExpression,
            },
            updateMask: {
                paths: ["schedule"]
            }
        });

        logger.info("Scheduler updated successfully.");

        res.status(200).json({
            success: true,
            message: "Scheduler updated successfully.",
        });
    } catch (error) {
        logger.error("Error updating Scheduler:", error);
        res.status(500).json({
            success: false,
            message: "Error updating Scheduler.",
        });
    }
});

exports.sendMilestoneMessages = onRequest({ cors: true }, async (req, res) => {
    try {

        if (req.method === "OPTIONS") {
            return res.status(200).send("OK");
        }

        if (req.method !== "POST") {
            return res.status(405).json({
                success: false,
                message: "Method not allowed.",
            });
        }

        logger.info("🎂 Starting Cron Job...");

        const { clientId, schedulerId } = req.body;

        //1. Fetch scheduler data
        const schedulerSnapshot = await db.collection("milestone_schedulars").doc(clientId).collection("data").doc(schedulerId).get();
        const schedulerData = schedulerSnapshot.data();

        const type = schedulerData.type;

        const parts = new Intl.DateTimeFormat('en-IN', {
            timeZone: 'Asia/Kolkata',
            day: '2-digit',
            month: '2-digit'
        }).formatToParts(new Date());

        const day = parts.find(p => p.type === 'day').value;
        const month = parts.find(p => p.type === 'month').value;

        const dayMonth = `${day} ${month}`;

        logger.info(`Checking ${type} milestones for Day/Month: ${dayMonth}`);

        // Query contacts with matching milestones
        let field, activeFilter;
        switch (type) {
            case 'birthday':
                field = "birthdateMonth";
                activeFilter = "isBirthdateActive";
                break;
            case 'anniversary':
                field = "anniversaryDateMonth";
                activeFilter = "isAnniversaryActive";
                break;
            case 'workAnniversary':
                field = "workAnniversaryDateMonth";
                activeFilter = "isWorkAnniversaryActive";
                break;
        }

        const snapshot = await db.collection("contacts").doc(clientId).collection("data")
            .where(field, "==", dayMonth)
            .where(activeFilter, "==", true)
            .get();

        if (snapshot.empty) {
            logger.info("No milestones found for today.");
            res.json({
                success: true,
                message: "No milestones found for today.",
            });
            return;
        }

        logger.info(`🎉 Found ${snapshot.size} milestones for today.`);

        // 2. Download the Main Image
        const backgroundBuffer = await fetch(schedulerData.backgroundUrl).then(async res => {
            if (!res.ok) {
                logger.info(`Failed to fetch background image for ${type}`);
                return null;
            }
            const arrayBuffer = await res.arrayBuffer();
            return Buffer.from(arrayBuffer);
        });

        // 3. Categorize Elements
        const backgroundImages = schedulerData.elements.filter(e => e.type === 'image');
        const textLayers = schedulerData.elements.filter(e => e.type === 'text');

        // Disable sharp cache to prevent memory leaks in serverless
        sharp.cache(false);

        // Process sequentially to save memory (Concurrency Limit = 1)
        for (const doc of snapshot.docs) {
            let compositeImage = null;
            let profilePicBuffer = null;

            try {
                const contact = doc.data();
                const contactId = doc.id;
                const name = `${contact.fName || ''} ${contact.lName || ''}`.trim();
                const phoneNumber = contact.countryCode + contact.phoneNumber;
                const profilePicUrl = contact.profilePhoto;

                if (!profilePicUrl) {
                    logger.info(`Skipping ${name}: No profile picture.`);
                    continue;
                }

                profilePicBuffer = await fetch(profilePicUrl).then(async res => {
                    if (!res.ok) {
                        logger.warn(`Failed to fetch profile picture for ${name}`);
                        return null;
                    }
                    const arrayBuffer = await res.arrayBuffer();
                    return Buffer.from(arrayBuffer);
                });

                if (!profilePicBuffer) {
                    continue;
                }

                // Generate Compressed Image
                compositeImage = await generateCompositeImage(
                    backgroundBuffer,
                    schedulerData.imageWidth,
                    schedulerData.imageHeight,
                    schedulerData.backgroundScale,
                    backgroundImages,
                    textLayers,
                    profilePicBuffer,
                    name
                );

                const mediaId = await createMediaId(compositeImage, "milestone.png", "image/png");

                // Clear Image Buffers Immediately
                compositeImage = null;
                profilePicBuffer = null;

                const bodyVariables = Object.values(schedulerData.variableValues || {})
                    .map(variable => {
                        if (variable.type === 'static') {
                            return variable.value;
                        }
                        const value = variable.value;
                        switch (value) {
                            case "First Name": return contact.fName || value;
                            case "Last Name": return contact.lName || value;
                            case "Email": return contact.email || value;
                            case "Company": return contact.company || value;
                            case "Birth Date": return contact.birthDate || value;
                            case "Anniversary": return contact.anniversaryDt || value;
                            case "Work Anniversary": return contact.workAnniversaryDt || value;
                            default: return value;
                        }
                    });

                const response = await sendWhatsAppTemplateMessageHelper({
                    clientId: clientId,
                    template: schedulerData.selectedTemplateName,
                    language: schedulerData.language,
                    type: "Media",
                    bodyVariables: bodyVariables,
                    headerVariables: { type: "image", data: { mediaId: mediaId } },
                    buttonVariables: null,
                    mobileNo: phoneNumber
                });

                if (response.success) {
                    logger.info(`✅ Sent milestone wish to ${name} (${phoneNumber})`);
                } else {
                    logger.error(`❌ Failed to send to ${name}:`, response.message);
                }

            } catch (err) {
                logger.error(`❌ Error processing contact ${doc.id}:`, err);
            } finally {
                // Safety cleanup
                if (compositeImage) compositeImage = null;
                if (profilePicBuffer) profilePicBuffer = null;
            }
        }

        await db.collection("milestone_schedulars").doc(clientId).collection("data").doc(schedulerId).update({
            lastRun: admin.firestore.FieldValue.serverTimestamp(),
        });

        logger.info("✅ Milestone Scheduler completed.");
        res.json({
            success: true,
            message: "Milestone Scheduler completed.",
        });

    } catch (error) {
        logger.error("❌ Critical Error in Milestone Scheduler:", error);
        res.status(500).json({
            success: false,
            message: "Error in Milestone Scheduler.",
        });
    }
});

// Helper to convert JSON styles to an SVG string
function createSvgText(el, scale, text) {
    const { color, font, fontSize, isBold, isItalic, textAlign, size } = el;

    // Fallbacks and formatting
    const weight = isBold ? 'bold' : 'normal';
    const style = isItalic ? 'italic' : 'normal';
    const fontFamily = font || 'sans-serif';

    // Dimensions
    const width = size.width;
    const height = size.height;

    // Color conversion (Int ARGB -> CSS Hex RGBA)
    let fill = 'black';
    if (color) {
        try {
            // 4293660955 -> FFD1151B (ARGB) -> #D1151BFF (RGBA)
            const hex = BigInt(color).toString(16).padStart(8, '0');
            const a = hex.slice(0, 2);
            const r = hex.slice(2, 4);
            const g = hex.slice(4, 6);
            const b = hex.slice(6, 8);
            fill = `#${r}${g}${b}${a}`;
        } catch (e) {
            logger.error("Error converting color:", color);
        }
    }

    // Alignment
    let textAnchor = 'middle';
    let x = '50%';
    const align = (textAlign || 'center').toLowerCase();

    if (align === 'left' || align.includes('start')) {
        textAnchor = 'start';
        x = '0';
    } else if (align === 'right' || align.includes('end')) {
        textAnchor = 'end';
        x = '100%';
    }

    return `
    <svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" xmlns="http://www.w3.org/2000/svg">
      <style>
        .text { 
          fill: ${fill}; 
          font-size: ${fontSize}px; 
          font-weight: ${weight}; 
          font-style: ${style};
          font-family: ${fontFamily};
        }
      </style>
      <text x="${x}" y="50%" text-anchor="${textAnchor}" dominant-baseline="middle" class="text">
        ${text}
      </text>
    </svg>`;
}

async function generateCompositeImage(mainImageBuffer, imageWidth, imageHeight, backgroundScale, backgroundImages, textLayers, backgroundImageBuffer, name) {
    try {
        // 4. Prepare Background Layers (The ones that go BEHIND)
        const bgComposites = await Promise.all(backgroundImages.map(async (el) => {
            const width = el.size.width;
            const height = el.size.height;

            const resizedImg = await sharp(backgroundImageBuffer)
                .resize(Math.round(width), Math.round(height), {
                    fit: 'contain'
                })
                .toBuffer();

            return {
                input: resizedImg,
                top: Math.round(el.position.dy),
                left: Math.round(el.position.dx),
            };
        }));

        logger.info(`Prepared ${bgComposites.length} background composites`);

        // 5. Prepare Text Layers (The ones that go ON TOP)
        const textComposites = textLayers.map(el => {
            const svgText = createSvgText(el, backgroundScale, name);
            return {
                input: Buffer.from(svgText),
                top: Math.round(el.position.dy),
                left: Math.round(el.position.dx),
            };
        });

        logger.info(`Prepared ${textComposites.length} text composites`);

        const finalImage = await sharp({
            create: {
                width: parseInt(imageWidth),
                height: parseInt(imageHeight),
                channels: 4,
                background: { r: 0, g: 0, b: 0, alpha: 0 }
            }
        })
            .composite([
                ...bgComposites,
                { input: mainImageBuffer, top: 0, left: 0 },
                ...textComposites
            ])
            .png({
                quality: 60,       // Reduce quality slightly for size
                palette: true,     // Use palette-based quantization (8-bit) for significant savings
                compressionLevel: 8 // High compression
            })
            .toBuffer();

        return finalImage;

    } catch (error) {
        logger.error("Error generating composite image:", error);
        throw error;
    }
}

function convertTimeToCron(timeString) {
    logger.info(`Converting time to cron: ${timeString}`);
    // Split the time string into time and modifier (AM/PM)
    const [time, modifier] = timeString.split(' ');
    let [hours, minutes] = time.split(':');

    if (hours === '12') {
        hours = '00';
    }

    if (modifier === 'PM') {
        hours = parseInt(hours, 10) + 12;
    }

    return `${minutes} ${hours} * * *`;
}