const API = {
  // Campaigns
  getCampaigns: async () => {
    try {
      const response = await fetch('/api/campaigns/');
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
      const response = await fetch('/api/endorsers/');
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
      const response = await fetch('/api/legislators/');
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