import type { NextConfig } from "next";

import { withSentryConfig } from "@sentry/nextjs";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      { protocol: "http", hostname: "localhost", port: "5021", pathname: "/**" },
      { protocol: "https", hostname: "*.amazonaws.com", pathname: "/**" },
    ],
  },
};

const isDev = process.env.NODE_ENV === "development";

export default isDev
  ? nextConfig
  : withSentryConfig(nextConfig, {
      silent: true,
      org: "rentlanka",
      project: "web-admin",
      widenClientFileUpload: true,
      tunnelRoute: "/monitoring",
      hideSourceMaps: true,
      disableLogger: true,
      automaticVercelMonitors: true,
    });
