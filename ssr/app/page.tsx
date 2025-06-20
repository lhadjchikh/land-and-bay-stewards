import { apiClient } from "../lib/api";
import { Campaign, HomePage } from "../types";
import Link from "next/link";
import HeroSection from "./components/HeroSection";
import ContentBlock from "./components/ContentBlock";
import SocialLinks from "./components/SocialLinks";
import type { Metadata } from "next";

export async function generateMetadata(): Promise<Metadata> {
  try {
    const homepage = await apiClient.getHomepage();
    return {
      title: homepage.organization_name,
      description: homepage.tagline,
      robots: "index, follow",
      generator: "Next.js",
      applicationName: homepage.organization_name,
      authors: [{ name: homepage.organization_name + " Team" }],
    };
  } catch {
    return {
      title: "Coalition Builder",
      description: "Building strong advocacy partnerships",
      robots: "index, follow",
      generator: "Next.js",
      applicationName: "Coalition Builder",
      authors: [{ name: "Coalition Builder Team" }],
    };
  }
}

export default async function HomePage() {
  let campaigns: Campaign[] = [];
  let homepage: HomePage | null = null;
  let error: string | null = null;

  try {
    // Fetch both homepage content and campaigns in parallel
    const [homepageData, campaignsData] = await Promise.all([
      apiClient.getHomepage(),
      apiClient.getCampaigns(),
    ]);

    homepage = homepageData;
    campaigns = campaignsData;
  } catch (err) {
    error = err instanceof Error ? err.message : "Failed to fetch content";
    console.error("Error fetching content:", err);
  }

  // Fallback homepage data if API fails
  const fallbackHomepage: HomePage = {
    id: 0,
    organization_name: process.env.ORGANIZATION_NAME || "Coalition Builder",
    tagline: process.env.TAGLINE || "Building strong advocacy partnerships",
    hero_title: "Welcome to Coalition Builder",
    hero_subtitle: "Empowering advocates to build strong policy coalitions",
    hero_background_image: "",
    about_section_title: "About Our Mission",
    about_section_content:
      "We believe in the power of collective action to drive meaningful policy change.",
    cta_title: "Get Involved",
    cta_content: "Join our coalition and help make a difference.",
    cta_button_text: "Learn More",
    cta_button_url: "",
    contact_email: "info@example.org",
    contact_phone: "",
    facebook_url: "",
    twitter_url: "",
    instagram_url: "",
    linkedin_url: "",
    campaigns_section_title: "Policy Campaigns",
    campaigns_section_subtitle: "",
    show_campaigns_section: true,
    content_blocks: [],
    is_active: true,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  const currentHomepage = homepage || fallbackHomepage;

  if (error && !homepage) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="max-w-md mx-auto">
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
            <p className="font-bold">Error loading page content</p>
            <p className="text-sm mt-1">{error}</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-white">
      {/* Hero Section */}
      <HeroSection homepage={currentHomepage} />

      {/* About Section */}
      {currentHomepage.about_section_content && (
        <section className="py-16 bg-white">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="text-center">
              <h2 className="text-3xl font-bold text-gray-900 sm:text-4xl">
                {currentHomepage.about_section_title}
              </h2>
              <div className="mt-6 text-xl text-gray-600 max-w-4xl mx-auto leading-relaxed">
                <div
                  dangerouslySetInnerHTML={{
                    __html: currentHomepage.about_section_content,
                  }}
                />
              </div>
            </div>
          </div>
        </section>
      )}

      {/* Dynamic Content Blocks */}
      {currentHomepage.content_blocks &&
        currentHomepage.content_blocks.length > 0 && (
          <>
            {currentHomepage.content_blocks
              .filter((block) => block.is_visible)
              .sort((a, b) => a.order - b.order)
              .map((block) => (
                <ContentBlock key={block.id} block={block} />
              ))}
          </>
        )}

      {/* Campaigns Section */}
      {currentHomepage.show_campaigns_section && (
        <section className="py-16 bg-gray-50">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="text-center">
              <h2 className="text-3xl font-bold text-gray-900 sm:text-4xl">
                {currentHomepage.campaigns_section_title}
              </h2>
              {currentHomepage.campaigns_section_subtitle && (
                <p className="mt-4 text-xl text-gray-600">
                  {currentHomepage.campaigns_section_subtitle}
                </p>
              )}
            </div>

            <div className="mt-12">
              {error && !campaigns.length ? (
                <div className="bg-yellow-100 border border-yellow-400 text-yellow-700 px-4 py-3 rounded">
                  <p>Unable to load campaigns at this time.</p>
                </div>
              ) : campaigns.length === 0 ? (
                <div className="text-center text-gray-600">
                  <p>No campaigns are currently available.</p>
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
          </div>
        </section>
      )}

      {/* Call to Action Section */}
      {currentHomepage.cta_content && (
        <section className="py-16 bg-blue-600">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            <h2 className="text-3xl font-bold text-white sm:text-4xl">
              {currentHomepage.cta_title}
            </h2>
            <p className="mt-4 text-xl text-blue-100">
              {currentHomepage.cta_content}
            </p>
            {currentHomepage.cta_button_url &&
              currentHomepage.cta_button_text && (
                <div className="mt-8">
                  <a
                    href={currentHomepage.cta_button_url}
                    className="inline-flex items-center px-8 py-3 border border-transparent text-base font-medium rounded-md text-blue-600 bg-white hover:bg-gray-50 transition-colors duration-200"
                  >
                    {currentHomepage.cta_button_text}
                  </a>
                </div>
              )}
          </div>
        </section>
      )}

      {/* Footer */}
      <footer className="bg-gray-900">
        <div className="max-w-7xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <h3 className="text-lg font-semibold text-white mb-4">
              {currentHomepage.organization_name}
            </h3>
            <p className="text-gray-300 mb-6">{currentHomepage.tagline}</p>

            {/* Contact Information */}
            <div className="mb-6">
              <p className="text-gray-300">
                <a
                  href={`mailto:${currentHomepage.contact_email}`}
                  className="hover:text-white transition-colors"
                >
                  {currentHomepage.contact_email}
                </a>
                {currentHomepage.contact_phone && (
                  <>
                    {" • "}
                    <a
                      href={`tel:${currentHomepage.contact_phone}`}
                      className="hover:text-white transition-colors"
                    >
                      {currentHomepage.contact_phone}
                    </a>
                  </>
                )}
              </p>
            </div>

            {/* Social Links */}
            <SocialLinks homepage={currentHomepage} />

            {/* API Documentation Link */}
            <div className="mt-8 pt-8 border-t border-gray-800">
              <Link
                href="/api/"
                className="text-sm text-gray-400 hover:text-gray-300 transition-colors"
                target="_blank"
                rel="noopener noreferrer"
              >
                View API Documentation
              </Link>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
