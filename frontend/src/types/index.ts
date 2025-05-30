// Campaign type definition
export interface Campaign {
  id: number;
  title: string;
  slug: string;
  summary: string;
  description?: string;
  created_at?: string;
  updated_at?: string;
}

// Endorser type definition
export interface Endorser {
  id: number;
  name: string;
  type: string;
  website?: string;
  description?: string;
}

// Legislator type definition
export interface Legislator {
  id: number;
  name: string;
  district: string;
  party?: string;
  contact_info?: string;
}