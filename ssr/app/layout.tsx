import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Land and Bay Stewards",
  description: "Protecting our waterways and coastal communities",
  viewport: "width=device-width, initial-scale=1",
  robots: "index, follow",
  generator: "Next.js",
  applicationName: "Land and Bay Stewards",
  authors: [{ name: "Land and Bay Stewards Team" }],
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
