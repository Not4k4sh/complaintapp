import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";

admin.initializeApp();

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "your-email@gmail.com",
    pass: "your-app-password",
  },
});

export const sendEmailNotification = functions.https.onCall(async (data, context) => {
  const { email, title, status } = data;

  const mailOptions = {
    from: "your-email@gmail.com",
    to: email,
    subject: `Update on Your Complaint: ${title}`,
    text: `Hello,\n\nYour complaint titled "${title}" has been updated to: ${status}.\n\nThank you,\nComplaint Management Team`,
  };

  try {
    await transporter.sendMail(mailOptions);
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
});
