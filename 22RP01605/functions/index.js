const functions = require('firebase-functions');
const nodemailer = require('nodemailer');

// Use Firebase environment config for credentials
const gmailEmail = functions.config().gmail.email;
const gmailPassword = functions.config().gmail.password;

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: gmailEmail,
        pass: gmailPassword,
    },
});

exports.sendGoalEmail = functions.https.onCall(async (data, context) => {
    const { to, subject, text } = data;

    if (!to || !subject || !text) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Missing required fields: to, subject, text'
        );
    }

    try {
        await transporter.sendMail({
            from: gmailEmail,
            to,
            subject,
            text,
        });
        console.log(`Email sent to ${to} with subject "${subject}"`);
        return { success: true };
    } catch (error) {
        console.error('Error sending email:', error);
        throw new functions.https.HttpsError('internal', error.message, error);
    }
}); 