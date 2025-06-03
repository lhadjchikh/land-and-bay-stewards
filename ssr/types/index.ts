export interface Campaign {
  id: number;
  title: string;
  slug: string;
  summary: string;
  description?: string;
  created_at?: string;
  updated_at?: string;
}

export interface Endorser {
  id: number;
  name: string;
  organization: string;
  state: string;
  type: string;
  role?: string;
  email?: string;
  county?: string;
  public_display?: boolean;
  statement?: string;
  created_at?: string;
}

export interface Legislator {
  id: number;
  first_name: string;
  last_name: string;
  chamber: string;
  state: string;
  district: string | null;
  is_senior: boolean | null;
  party?: string;
  bioguide_id?: string;
  in_office?: boolean;
  url?: string;
}

export interface ApiResponse<T> {
  data: T;
  status: number;
  message?: string;
}

export interface PageProps {
  campaigns?: Campaign[];
  endorsers?: Endorser[];
  legislators?: Legislator[];
  error?: string;
}
