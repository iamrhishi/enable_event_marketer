// EmailJS Configuration for Enable Event Marketer
// Instructions for setup:
// 1. Go to https://www.emailjs.com/
// 2. Create an account and get your User ID
// 3. Create a service (Gmail, Outlook, etc.)
// 4. Create email templates
// 5. Replace the placeholder values below with your actual EmailJS credentials

export const EMAILJS_CONFIG = {
  // Replace with your EmailJS Service ID
  SERVICE_ID: process.env.REACT_APP_EMAILJS_SERVICE_ID || 'service_1yw14fl',
  
  // Replace with your EmailJS Template ID for use case sharing
  TEMPLATE_ID_USECASE: process.env.REACT_APP_EMAILJS_TEMPLATE_ID || 'template_fblrsyj',
  
  // Replace with your EmailJS Template ID for engagement tracking
  TEMPLATE_ID_ENGAGEMENT: 'template_engagement',
  
  // Replace with your EmailJS Public Key
  PUBLIC_KEY: process.env.REACT_APP_EMAILJS_PUBLIC_KEY || 'JRlNiE2UYdy-ePk0e',
  
  // Target email address
  TARGET_EMAIL: 'engineering@enableyou.co'
};

// Email templates configuration
export const EMAIL_TEMPLATES = {
  usecase_share: {
    subject: 'Enable Use Case Share: {{use_case_title}}',
    to_email: '{{to_email}}',
    from_email: '{{from_email}}',
    use_case_title: '{{use_case_title}}',
    use_case_outcome: '{{use_case_outcome}}',
    use_case_problem: '{{use_case_problem}}',
    use_case_solution: '{{use_case_solution}}',
    use_case_personas: '{{use_case_personas}}',
    use_case_categories: '{{use_case_categories}}',
    user_email: '{{user_email}}',
    timestamp: '{{timestamp}}',
    user_agent: '{{user_agent}}',
    page_url: '{{page_url}}'
  },
  
  engagement: {
    subject: 'Enable User Engagement: {{action}}',
    to_email: '{{to_email}}',
    from_email: '{{from_email}}',
    action: '{{action}}',
    user_email: '{{user_email}}',
    timestamp: '{{timestamp}}',
    user_agent: '{{user_agent}}',
    page_url: '{{page_url}}'
  }
};

// Setup instructions for EmailJS
export const SETUP_INSTRUCTIONS = `
EmailJS Setup Instructions:

1. Go to https://www.emailjs.com/ and create an account
2. Create a new service (Gmail, Outlook, etc.)
3. Create email templates:
   - Template 1: "template_usecase_share" for use case sharing
   - Template 2: "template_engagement" for engagement tracking
4. Get your Public Key from the integration page
5. Replace the placeholder values in EMAILJS_CONFIG with your actual credentials
6. Test the email functionality

Email Template Variables:
- {{to_email}} - Target email (engineering@enableyou.co)
- {{from_email}} - User's email
- {{use_case_title}} - Use case title
- {{use_case_outcome}} - Use case outcome
- {{use_case_problem}} - Use case problem
- {{use_case_solution}} - Use case solution
- {{use_case_personas}} - Use case personas
- {{use_case_categories}} - Use case categories
- {{user_email}} - User's email
- {{timestamp}} - Current timestamp
- {{user_agent}} - User's browser info
- {{page_url}} - Current page URL
- {{action}} - Engagement action type
`;
