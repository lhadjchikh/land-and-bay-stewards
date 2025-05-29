import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import CampaignsList from '../../components/CampaignsList';

describe('CampaignsList Integration', () => {
  beforeEach(() => {
    // Clear all mocks
    fetch.mockClear();
  });

  test('renders campaigns from API', async () => {
    // Mock successful API response
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => [{
        id: 1,
        title: 'Test Campaign',
        slug: 'test-campaign',
        summary: 'This is a test campaign'
      }]
    });

    render(<CampaignsList />);
    
    // Initially should show loading state
    expect(screen.getByTestId('loading')).toBeInTheDocument();
    
    // Wait for the API call to resolve
    await waitFor(() => {
      expect(screen.getByTestId('campaigns-list')).toBeInTheDocument();
    });
    
    // Verify API was called with correct endpoint
    expect(fetch).toHaveBeenCalledWith('/api/campaigns/');
    
    // Check that campaign data is displayed
    expect(screen.getByText('Test Campaign')).toBeInTheDocument();
    expect(screen.getByText('This is a test campaign')).toBeInTheDocument();
  });

  test('handles API error states', async () => {
    // Mock API error response
    fetch.mockRejectedValueOnce(new Error('API Error'));
    
    render(<CampaignsList />);
    
    // Wait for the error message
    await waitFor(() => {
      expect(screen.getByTestId('error')).toBeInTheDocument();
    });
    
    expect(screen.getByText('Failed to fetch campaigns')).toBeInTheDocument();
  });

  test('handles empty response from API', async () => {
    // Mock empty API response
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => []
    });
    
    render(<CampaignsList />);
    
    // Wait for the component to load
    await waitFor(() => {
      expect(screen.getByTestId('campaigns-list')).toBeInTheDocument();
    });
    
    expect(screen.getByText('No campaigns found')).toBeInTheDocument();
  });
});