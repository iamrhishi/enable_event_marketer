// Email Service for Enable Event Marketer
// This service handles sending emails to engineering@enableyou.co

import emailjs from '@emailjs/browser';
import { EMAILJS_CONFIG } from '../config/emailConfig';

// Initialize EmailJS with Public Key
emailjs.init(EMAILJS_CONFIG.PUBLIC_KEY);

/**
 * Send use case details to engineering@enableyou.co
 * @param {string} userEmail - The email address of the user who shared the use case
 * @param {Object} useCaseData - The use case data to be shared
 * @returns {Promise} - Promise that resolves when email is sent
 */
export const sendUseCaseEmail = async (userEmail, useCaseData) => {
  try {
      const templateParams = {
        to_email: EMAILJS_CONFIG.TARGET_EMAIL,
        from_email: userEmail,
        use_case_title: useCaseData.title,
        user_email: userEmail
      };

    const response = await emailjs.send(
      EMAILJS_CONFIG.SERVICE_ID,
      EMAILJS_CONFIG.TEMPLATE_ID_USECASE,
      templateParams
    );

    console.log('Email sent successfully:', response);
    return { success: true, response };
  } catch (error) {
    console.error('Failed to send email:', error);
    return { success: false, error };
  }
};

/**
 * Send a simple notification email about user engagement
 * @param {string} userEmail - The email address of the user
 * @param {string} action - The action performed (e.g., 'content_unlocked', 'use_case_viewed')
 * @returns {Promise} - Promise that resolves when email is sent
 */
export const sendEngagementEmail = async (userEmail, action = 'content_unlocked') => {
  try {
    const templateParams = {
      to_email: EMAILJS_CONFIG.TARGET_EMAIL,
      from_email: userEmail,
      action: action,
      user_email: userEmail,
      timestamp: new Date().toISOString(),
      user_agent: navigator.userAgent,
      page_url: window.location.href
    };

    const response = await emailjs.send(
      EMAILJS_CONFIG.SERVICE_ID,
      EMAILJS_CONFIG.TEMPLATE_ID_ENGAGEMENT,
      templateParams
    );

    console.log('Engagement email sent successfully:', response);
    return { success: true, response };
  } catch (error) {
    console.error('Failed to send engagement email:', error);
    return { success: false, error };
  }
};

/**
 * Fallback email method using mailto link
 * @param {string} userEmail - The email address of the user
 * @param {Object} useCaseData - The use case data to be shared
 */
export const sendFallbackEmail = (userEmail, useCaseData) => {
  const subject = `Enable Use Case Share: ${useCaseData.title}`;
  const body = `
Hi Enable Team,

A user has shared a use case from the Enable Event Marketer:

**User Information:**
- User Email: ${userEmail}

**Use Case Details:**
- Title: ${useCaseData.title}

This email was automatically generated when the user unlocked content on the Enable Event Marketer platform.

Best regards,
Enable Event Marketer System
  `.trim();

  const mailtoLink = `mailto:${EMAILJS_CONFIG.TARGET_EMAIL}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
  window.open(mailtoLink, '_blank');
};

// Configuration helper for EmailJS setup
export const getEmailJSConfig = () => ({
  serviceId: EMAILJS_CONFIG.SERVICE_ID,
  templateId: EMAILJS_CONFIG.TEMPLATE_ID_USECASE,
  publicKey: EMAILJS_CONFIG.PUBLIC_KEY
});
