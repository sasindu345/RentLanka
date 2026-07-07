import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.SENTRY_DSN || "https://d9fbb3f7215c4d3da9f1a26bfa33d456@o4507000000000000.ingest.us.sentry.io/4507000000000000",
  
  // Adjust this value in production, or use tracesSampler for greater control
  tracesSampleRate: 1.0,

  // Setting this option to true will print useful information to the console regarding SDK integration.
  debug: false,
});
