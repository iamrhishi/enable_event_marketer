// API Configuration for Enable Event Marketer
// For development: use localhost backend
// For production: update with your server IP address
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000';

export const API_ENDPOINTS = {
  // Events
  EVENTS: `${API_BASE_URL}/api/events`,
  EVENT_BY_ID: (id) => `${API_BASE_URL}/api/events/${id}`,
  
  // Health check
  HEALTH: `${API_BASE_URL}/api/health`,
};

export default API_BASE_URL;
