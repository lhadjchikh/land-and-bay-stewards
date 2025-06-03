import { Campaign, Endorser, Legislator } from "@/types";

const API_URL =
  process.env.API_URL ||
  process.env.NEXT_PUBLIC_API_URL ||
  "http://localhost:8000";

class ApiClient {
  private baseURL: string;

  constructor(baseURL: string = API_URL) {
    this.baseURL = baseURL;
  }

  private async request<T>(endpoint: string): Promise<T> {
    const url = `${this.baseURL}${endpoint}`;

    try {
      const response = await fetch(url, {
        headers: {
          "Content-Type": "application/json",
        },
        // Add cache settings for SSR
        next: {
          revalidate: 300, // Revalidate every 5 minutes
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error(`API request failed for ${url}:`, error);
      throw error;
    }
  }

  // Campaigns
  async getCampaigns(): Promise<Campaign[]> {
    return this.request<Campaign[]>("/api/campaigns/");
  }

  async getCampaign(id: number): Promise<Campaign> {
    return this.request<Campaign>(`/api/campaigns/${id}/`);
  }

  // Endorsers
  async getEndorsers(): Promise<Endorser[]> {
    return this.request<Endorser[]>("/api/endorsers/");
  }

  // Legislators
  async getLegislators(): Promise<Legislator[]> {
    return this.request<Legislator[]>("/api/legislators/");
  }

  // Health check
  async healthCheck(): Promise<{ status: string }> {
    return this.request<{ status: string }>("/api/health/");
  }
}

// Export singleton instance
export const apiClient = new ApiClient();
export default apiClient;
