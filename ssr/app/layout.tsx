import type { Metadata } from "next";
import "./globals.css";

const org = process.env.ORGANIZATION_NAME || "Coalition Builder";
export const metadata: Metadata = {
  title: org,
  description: process.env.TAGLINE || "Building strong advocacy partnerships",
  viewport: "width=device-width, initial-scale=1",
  robots: "index, follow",
  generator: "Next.js",
  applicationName: org,
  authors: [{ name: org + " Team" }],
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        {/* The head tag is optional in Next.js App Router,
            but we include it explicitly to ensure it's present for SSR tests */}
      </head>
      <body>
        <div data-ssr="true" id="app-root">
          {children}
        </div>
      </body>
    </html>
  );
}
