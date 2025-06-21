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

export interface ContentBlock {
  id: number;
  title: string;
  block_type: string;
  content: string;
  image_url: string;
  image_alt_text: string;
  css_classes: string;
  background_color: string;
  order: number;
  is_visible: boolean;
  created_at: string;
  updated_at: string;
}

export interface HomePage {
  id: number;
  // Organization info
  organization_name: string;
  tagline: string;

  // Hero section
  hero_title: string;
  hero_subtitle: string;
  hero_background_image: string;

  // Main content sections
  about_section_title: string;
  about_section_content: string;

  // Call to action
  cta_title: string;
  cta_content: string;
  cta_button_text: string;
  cta_button_url: string;

  // Contact information
  contact_email: string;
  contact_phone: string;

  // Social media
  facebook_url: string;
  twitter_url: string;
  instagram_url: string;
  linkedin_url: string;

  // Campaign section customization
  campaigns_section_title: string;
  campaigns_section_subtitle: string;
  show_campaigns_section: boolean;

  // Content blocks
  content_blocks: ContentBlock[];

  // Meta information
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface PageProps {
  campaigns?: Campaign[];
  endorsers?: Endorser[];
  legislators?: Legislator[];
  homepage?: HomePage;
  error?: string;
}
