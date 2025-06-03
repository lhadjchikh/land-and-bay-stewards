import { apiClient } from "../lib/api";
import { Campaign } from "../types";
import Link from "next/link";

export default async function HomePage() {
  let campaigns: Campaign[] = [];
  let error: string | null = null;

  try {
    campaigns = await apiClient.getCampaigns();
  } catch (err) {
    error = err instanceof Error ? err.message : "Failed to fetch campaigns";
    console.error("Error fetching campaigns:", err);
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
        <div className="text-center">
          <h1 className="text-4xl font-bold text-gray-900 sm:text-5xl">
            Land and Bay Stewards
          </h1>
          <p className="mt-4 text-xl text-gray-600">
            Protecting our waterways and coastal communities
          </p>
        </div>

        <div className="mt-12">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">
            Policy Campaigns
          </h2>

          {error ? (
            <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
              <p>Error loading campaigns: {error}</p>
            </div>
          ) : campaigns.length === 0 ? (
            <div className="bg-yellow-100 border border-yellow-400 text-yellow-700 px-4 py-3 rounded">
              <p>No campaigns found.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {campaigns.map((campaign) => (
                <div
                  key={campaign.id}
                  className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow"
                >
                  <h3 className="text-lg font-semibold text-gray-900 mb-2">
                    {campaign.title}
                  </h3>
                  <p className="text-gray-600 mb-4">{campaign.summary}</p>
                  <Link
                    href={`/campaigns/${campaign.slug}`}
                    className="text-blue-600 hover:text-blue-800 font-medium"
                  >
                    Learn more →
                  </Link>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="mt-12 text-center">
          <Link
            href="/api/"
            className="text-sm text-gray-500 hover:text-gray-700"
            target="_blank"
            rel="noopener noreferrer"
          >
            View API Documentation
          </Link>
        </div>
      </div>
    </div>
  );
}
