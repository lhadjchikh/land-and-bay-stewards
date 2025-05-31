import React, { useState, useEffect } from 'react';
import API from '../services/api';
import { Campaign } from '../types';

const CampaignsList: React.FC = () => {
  const [campaigns, setCampaigns] = useState<Campaign[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchCampaigns = async (): Promise<void> => {
      try {
        const data = await API.getCampaigns();
        setCampaigns(data);
        setLoading(false);
      } catch (err) {
        setError('Failed to fetch campaigns');
        setLoading(false);
      }
    };

    fetchCampaigns();
  }, []);

  if (loading) return <div data-testid="loading">Loading campaigns...</div>;
  if (error) return <div data-testid="error">{error}</div>;

  return (
    <div className="campaigns-list" data-testid="campaigns-list">
      <h2>Policy Campaigns</h2>
      {campaigns.length === 0 ? (
        <p>No campaigns found</p>
      ) : (
        <ul>
          {campaigns.map(campaign => (
            <li key={campaign.id} data-testid={`campaign-${campaign.id}`}>
              <h3>{campaign.title}</h3>
              <p>{campaign.summary}</p>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
};

export default CampaignsList;
