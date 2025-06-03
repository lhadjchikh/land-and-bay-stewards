/** @type {import('next').NextConfig} */
const nextConfig = {
  // Enable standalone output for Docker
  output: "standalone",

  // Environment variables
  env: {
    NEXT_PUBLIC_API_URL:
      process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000",
  },
  serverRuntimeConfig: {
    API_URL: process.env.API_URL || "http://localhost:8000",
  },

  // Rewrites for API calls (optional - for development)
  async rewrites() {
    return [
      {
        source: "/api/:path*",
        destination: `${
          process.env.API_URL || "http://localhost:8000"
        }/api/:path*`,
      },
    ];
  },

  // Optimize for production
  compiler: {
    removeConsole: process.env.NODE_ENV === "production",
  },

  // Images configuration
  images: {
    domains: ["localhost"],
  },
};

module.exports = nextConfig;
