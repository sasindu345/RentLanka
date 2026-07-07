import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN || "https://0370d698d70eacab62830dd0115a1174@o4511590911836160.ingest.us.sentry.io/4511694272069632",
  
  // Adjust this value in production, or use tracesSampler for greater control
  tracesSampleRate: 1.0,

  // Setting this option to true will print useful information to the console regarding SDK integration.
  debug: false,
});
