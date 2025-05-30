// Determine the API base URL
const getBaseUrl = () => {
  // In CI/E2E tests with Docker, use the service name from docker-compose
  if (process.env.REACT_APP_API_URL) {
    return process.env.REACT_APP_API_URL;
  }
  
  // If running in the context of CI/CD but no explicit API URL
  if (process.env.CI === 'true') {
    return 'http://localhost:8000';
  }
  
  // Default for local development
  return '';
};

const API = {
  // Export getBaseUrl for testing
  getBaseUrl,
  
  // Campaigns
  getCampaigns: async () => {
    try {
      const response = await fetch(`${getBaseUrl()}/api/campaigns/`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return await response.json();
    } catch (error) {
      console.error('Error fetching campaigns:', error);
      throw error;
    }
  },

  // Endorsers
  getEndorsers: async () => {
    try {
      const response = await fetch(`${getBaseUrl()}/api/endorsers/`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return await response.json();
    } catch (error) {
      console.error('Error fetching endorsers:', error);
      throw error;
    }
  },

  // Legislators
  getLegislators: async () => {
    try {
      const response = await fetch(`${getBaseUrl()}/api/legislators/`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return await response.json();
    } catch (error) {
      console.error('Error fetching legislators:', error);
      throw error;
    }
  }
};

export default API;