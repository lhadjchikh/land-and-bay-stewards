/**
 * This file contains end-to-end integration tests that verify
 * the connection between the frontend and backend.
 * 
 * NOTE: These tests require the backend server to be running.
 * Run the backend server with:
 * 
 * cd ../backend && python manage.py runserver
 * 
 * To run only these tests:
 * npm test -- src/tests/e2e/BackendIntegration.test.js
 */

import API from '../../services/api';

// Only skip if explicitly told to skip via env var
const shouldSkip = process.env.SKIP_E2E === 'true';

// Use conditionally running tests with test.skip
(shouldSkip ? describe.skip : describe)('Backend Integration Tests', () => {
  // Set a longer timeout for these tests since they require network calls
  jest.setTimeout(10000);

  // Use global.fetch instead of our mock
  beforeAll(() => {
    // Save the original fetch
    global.originalFetch = global.fetch;
    // Use the real fetch for these tests
    global.fetch = window.fetch;
  });

  // Restore the mock after these tests
  afterAll(() => {
    global.fetch = global.originalFetch;
  });

  test('Can fetch campaigns from the backend', async () => {
    try {
      console.log('Testing API URL:', process.env.REACT_APP_API_URL || 'default');
      console.log('Fetching campaigns from:', `${API.getBaseUrl ? API.getBaseUrl() : ''}/api/campaigns/`);
      
      const campaigns = await API.getCampaigns();
      console.log('Campaigns response:', campaigns ? 'Received data' : 'No data');
      
      // Verify we got an array response
      expect(Array.isArray(campaigns)).toBe(true);
      
      // If there are campaigns, verify they have the expected structure
      if (campaigns.length > 0) {
        const campaign = campaigns[0];
        console.log('First campaign:', campaign);
        expect(campaign).toHaveProperty('id');
        expect(campaign).toHaveProperty('title');
        expect(campaign).toHaveProperty('slug');
        expect(campaign).toHaveProperty('summary');
      } else {
        console.log('No campaigns found in the database, but API call succeeded');
      }
    } catch (error) {
      console.error('Detailed error:', error);
      // This will cause the test to fail, but with a more helpful message
      throw new Error(`Backend connection failed: ${error.message}. Make sure the backend server is running at http://localhost:8000`);
    }
  });

  test('Can fetch endorsers from the backend', async () => {
    try {
      const endorsers = await API.getEndorsers();
      
      // Verify we got an array response
      expect(Array.isArray(endorsers)).toBe(true);
      
      // If there are endorsers, verify they have the expected structure
      if (endorsers.length > 0) {
        const endorser = endorsers[0];
        expect(endorser).toHaveProperty('id');
        expect(endorser).toHaveProperty('name');
        expect(endorser).toHaveProperty('organization');
        expect(endorser).toHaveProperty('state');
        expect(endorser).toHaveProperty('type');
      }
    } catch (error) {
      throw new Error(`Backend connection failed: ${error.message}. Make sure the backend server is running at http://localhost:8000`);
    }
  });

  test('Can fetch legislators from the backend', async () => {
    try {
      const legislators = await API.getLegislators();
      
      // Verify we got an array response
      expect(Array.isArray(legislators)).toBe(true);
      
      // If there are legislators, verify they have the expected structure
      if (legislators.length > 0) {
        const legislator = legislators[0];
        expect(legislator).toHaveProperty('id');
        expect(legislator).toHaveProperty('first_name');
        expect(legislator).toHaveProperty('last_name');
        expect(legislator).toHaveProperty('chamber');
        expect(legislator).toHaveProperty('state');
        expect(legislator).toHaveProperty('district');
        expect(legislator).toHaveProperty('is_senior');
      }
    } catch (error) {
      throw new Error(`Backend connection failed: ${error.message}. Make sure the backend server is running at http://localhost:8000`);
    }
  });
});