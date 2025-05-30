import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import CampaignsList from '../../components/CampaignsList';
import API from '../../services/api';

// Mock the API module
jest.mock('../../services/api', () => ({
  getCampaigns: jest.fn(),
  getEndorsers: jest.fn(),
  getLegislators: jest.fn(),
  getBaseUrl: jest.fn(() => '')
}));

describe('CampaignsList Integration', () => {
  beforeEach(() => {
    // Clear all mocks
    jest.clearAllMocks();
  });

  test('renders campaigns from API', async () => {
    // Mock data for the test
    const mockData = [{
      id: 1,
      title: 'Test Campaign',
      slug: 'test-campaign',
      summary: 'This is a test campaign'
    }];
    
    // Setup the API mock to return data
    API.getCampaigns.mockResolvedValue(mockData);
    
    render(<CampaignsList />);
    
    // Initially should show loading state
    expect(screen.getByTestId('loading')).toBeInTheDocument();
    
    // Wait for the component to update with a longer timeout
    await waitFor(() => {
      expect(screen.getByTestId('campaigns-list')).toBeInTheDocument();
    }, { timeout: 3000 });
    
    // Verify API was called
    expect(API.getCampaigns).toHaveBeenCalledTimes(1);
    
    // Check that campaign data is displayed
    expect(screen.getByText('Test Campaign')).toBeInTheDocument();
    expect(screen.getByText('This is a test campaign')).toBeInTheDocument();
  });

  test('handles API error states', async () => {
    // Mock API error
    API.getCampaigns.mockRejectedValue(new Error('API Error'));
    
    render(<CampaignsList />);
    
    // Initially should show loading state
    expect(screen.getByTestId('loading')).toBeInTheDocument();
    
    // Wait for the error message with a longer timeout
    await waitFor(() => {
      expect(screen.getByTestId('error')).toBeInTheDocument();
    }, { timeout: 3000 });
    
    expect(screen.getByText('Failed to fetch campaigns')).toBeInTheDocument();
  });

  test('handles empty response from API', async () => {
    // Mock empty array response
    API.getCampaigns.mockResolvedValue([]);
    
    render(<CampaignsList />);
    
    // Initially should show loading state
    expect(screen.getByTestId('loading')).toBeInTheDocument();
    
    // Wait for the component to load with a longer timeout
    await waitFor(() => {
      expect(screen.getByTestId('campaigns-list')).toBeInTheDocument();
    }, { timeout: 3000 });
    
    expect(screen.getByText('No campaigns found')).toBeInTheDocument();
  });
});