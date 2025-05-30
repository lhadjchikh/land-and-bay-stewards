import { Campaign, Endorser, Legislator } from '../types';

// Determine the API base URL
const getBaseUrl = (): string => {
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
  getCampaigns: async (): Promise<Campaign[]> => {
    try {
      const response = await fetch(`${getBaseUrl()}/api/campaigns/`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return await response.json() as Campaign[];
    } catch (error) {
      console.error('Error fetching campaigns:', error);
      throw error;
    }
  },

  // Endorsers
  getEndorsers: async (): Promise<Endorser[]> => {
    try {
      const response = await fetch(`${getBaseUrl()}/api/endorsers/`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return await response.json() as Endorser[];
    } catch (error) {
      console.error('Error fetching endorsers:', error);
      throw error;
    }
  },

  // Legislators
  getLegislators: async (): Promise<Legislator[]> => {
    try {
      const response = await fetch(`${getBaseUrl()}/api/legislators/`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return await response.json() as Legislator[];
    } catch (error) {
      console.error('Error fetching legislators:', error);
      throw error;
    }
  }
};

export default API;