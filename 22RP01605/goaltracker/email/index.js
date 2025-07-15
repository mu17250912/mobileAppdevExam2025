/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onCall} = require("firebase-functions/v2/https");
const nodemailer = require("nodemailer");

// Configure transporter with Gmail and app password for GoalTracker
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "dhozana559@gmail.com",
    pass: "xwvp owtn rprr dkxz",
  },
});

exports.sendGoalEmail = onCall(async (request) => {
  const {to, subject, text} = request.data;
  const mailOptions = {
    from: "dhozana559@gmail.com",
    to,
    subject,
    text,
  };
  try {
    await transporter.sendMail(mailOptions);
    return {success: true};
  } catch (error) {
    return {success: false, error: error.toString()};
  }
});
