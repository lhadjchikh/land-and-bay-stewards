import { render, screen, waitFor } from '@testing-library/react';
import App from './App';
import * as API from './services/api';

// Mock the API calls
jest.mock('./services/api', () => ({
  getCampaigns: jest.fn(),
  getEndorsers: jest.fn(),
  getLegislators: jest.fn(),
}));

describe('App component', () => {
  beforeEach(() => {
    // Default mock implementation for API calls
    API.getCampaigns.mockResolvedValue([{
      id: 1,
      title: 'Test Campaign',
      slug: 'test-campaign',
      summary: 'This is a test campaign'
    }]);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  test('renders Land and Bay Stewards title', () => {
    render(<App />);
    const headingElement = screen.getByText(/Land and Bay Stewards/i);
    expect(headingElement).toBeInTheDocument();
  });

  test('renders learn react link', () => {
    render(<App />);
    const linkElement = screen.getByText(/learn react/i);
    expect(linkElement).toBeInTheDocument();
  });

  test('renders the logo image correctly', () => {
    render(<App />);
    const logoElement = screen.getByAltText('logo');
    expect(logoElement).toBeInTheDocument();
    expect(logoElement.tagName).toBe('IMG');
    expect(logoElement).toHaveClass('App-logo');
    expect(logoElement.src).toMatch(/logo\.svg$/);
  });

  test('static assets are properly loaded', () => {
    render(<App />);
    const logoElement = screen.getByAltText('logo');
    
    // Check that the image source isn't broken
    expect(logoElement.src).not.toBe('');
    expect(logoElement.src).toBeDefined();
    
    // Test for CSS styles from App.css being applied
    const appHeader = screen.getByRole('banner');
    expect(appHeader).toHaveClass('App-header');
    
    const appLink = screen.getByText(/learn react/i);
    expect(appLink).toHaveClass('App-link');
  });

  test('renders CampaignsList component', async () => {
    render(<App />);
    
    // First it should show loading state
    expect(screen.getByTestId('loading')).toBeInTheDocument();
    
    // Wait for campaigns to load
    await waitFor(() => {
      expect(screen.getByTestId('campaigns-list')).toBeInTheDocument();
    });
    
    // Verify API was called
    expect(API.getCampaigns).toHaveBeenCalledTimes(1);
    
    // Verify campaign data is displayed
    expect(screen.getByText('Test Campaign')).toBeInTheDocument();
  });

  test('handles API errors gracefully', async () => {
    // Override the mock to simulate an error
    API.getCampaigns.mockRejectedValueOnce(new Error('API Error'));
    
    render(<App />);
    
    // Wait for the error message
    await waitFor(() => {
      expect(screen.getByTestId('error')).toBeInTheDocument();
    });
    
    expect(screen.getByText('Failed to fetch campaigns')).toBeInTheDocument();
  });
});
