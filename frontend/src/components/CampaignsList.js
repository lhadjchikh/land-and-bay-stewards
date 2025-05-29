import React, { useState, useEffect } from 'react';
import API from '../services/api';

function CampaignsList() {
  const [campaigns, setCampaigns] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchCampaigns = async () => {
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
}

export default CampaignsList;