import { HomePage } from "../../types";

interface HeroSectionProps {
  homepage: HomePage;
}

export default function HeroSection({ homepage }: HeroSectionProps) {
  const heroStyle: React.CSSProperties = homepage.hero_background_image
    ? {
        backgroundImage: `linear-gradient(rgba(0, 0, 0, 0.4), rgba(0, 0, 0, 0.4)), url(${homepage.hero_background_image})`,
        backgroundSize: "cover",
        backgroundPosition: "center",
        backgroundRepeat: "no-repeat",
      }
    : {};

  const textColorClass = homepage.hero_background_image
    ? "text-white"
    : "text-gray-900";

  return (
    <div
      className={`relative py-24 sm:py-32 ${homepage.hero_background_image ? "text-white" : "bg-gray-50"}`}
      style={heroStyle}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center">
          <h1
            className={`text-4xl font-bold ${textColorClass} sm:text-5xl lg:text-6xl`}
          >
            {homepage.hero_title}
          </h1>
          {homepage.hero_subtitle && (
            <p
              className={`mt-6 text-xl ${textColorClass} max-w-3xl mx-auto leading-relaxed`}
            >
              {homepage.hero_subtitle}
            </p>
          )}

          {/* Optional CTA button in hero */}
          {homepage.cta_button_url && homepage.cta_button_text && (
            <div className="mt-10">
              <a
                href={homepage.cta_button_url}
                className={`inline-flex items-center px-8 py-3 border border-transparent text-base font-medium rounded-md transition-colors duration-200 ${
                  homepage.hero_background_image
                    ? "text-gray-900 bg-white hover:bg-gray-50"
                    : "text-white bg-blue-600 hover:bg-blue-700"
                }`}
              >
                {homepage.cta_button_text}
              </a>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
