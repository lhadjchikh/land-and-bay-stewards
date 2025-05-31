import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import App from '../../App';
import API from '../../services/api';

// Mock the API module
jest.mock('../../services/api', () => ({
  getCampaigns: jest.fn(),
  getEndorsers: jest.fn(),
  getLegislators: jest.fn(),
}));

describe('App Integration Test', () => {
  // Arrange - Setup mock data
  const mockCampaigns = [
    {
      id: 1,
      title: 'Save the Bay',
      slug: 'save-the-bay',
      summary: 'Campaign to protect the Chesapeake Bay',
    },
    {
      id: 2,
      title: 'Clean Water Initiative',
      slug: 'clean-water',
      summary: 'Ensuring clean water for all communities',
    },
  ];

  beforeEach(() => {
    // Reset and setup mocks before each test
    jest.clearAllMocks();

    // Mock implementation of getCampaigns
    API.getCampaigns.mockResolvedValue(mockCampaigns);
  });

  test('fetches and displays campaigns in the app', async () => {
    // Act - Render the App
    render(<App />);

    // Initial loading state
    expect(screen.getByTestId('loading')).toBeInTheDocument();

    // Assert - Verify campaigns are displayed after loading
    await waitFor(() => {
      expect(screen.getByTestId('campaigns-list')).toBeInTheDocument();
    });

    // Check that the API was called exactly once
    expect(API.getCampaigns).toHaveBeenCalledTimes(1);

    // Verify both campaign titles are displayed
    expect(screen.getByText('Save the Bay')).toBeInTheDocument();
    expect(screen.getByText('Clean Water Initiative')).toBeInTheDocument();

    // Verify campaign summaries
    expect(screen.getByText('Campaign to protect the Chesapeake Bay')).toBeInTheDocument();
    expect(screen.getByText('Ensuring clean water for all communities')).toBeInTheDocument();
  });

  test('displays app title and campaigns together', async () => {
    // Act - Render the App
    render(<App />);

    // Assert - Check for app title
    expect(screen.getByText('Land and Bay Stewards')).toBeInTheDocument();

    // Wait for campaigns to load
    await waitFor(() => {
      expect(screen.getByTestId('campaigns-list')).toBeInTheDocument();
    });

    // Verify that app title and campaigns list exist together
    expect(screen.getByText('Land and Bay Stewards')).toBeInTheDocument();
    expect(screen.getByText('Policy Campaigns')).toBeInTheDocument();
    expect(screen.getByText('Save the Bay')).toBeInTheDocument();
  });

  test('handles API error in the app context', async () => {
    // Override the mock for this specific test to simulate an error
    API.getCampaigns.mockRejectedValueOnce(new Error('Failed to fetch data'));

    // Act - Render the App
    render(<App />);

    // Assert - Verify error state is displayed
    await waitFor(() => {
      expect(screen.getByTestId('error')).toBeInTheDocument();
    });

    expect(screen.getByText('Failed to fetch campaigns')).toBeInTheDocument();

    // Verify that even with an error, the app header is still displayed
    expect(screen.getByText('Land and Bay Stewards')).toBeInTheDocument();
  });
});
