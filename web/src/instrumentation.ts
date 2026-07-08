import * as Sentry from "@sentry/nextjs";

export function register() {
  if (process.env.NODE_ENV === "development") {
    return;
  }

  if (process.env.NEXT_RUNTIME === "nodejs") {
    Sentry.init({
      dsn: process.env.SENTRY_DSN || "https://0370d698d70eacab62830dd0115a1174@o4511590911836160.ingest.us.sentry.io/4511694272069632",
      tracesSampleRate: 1.0,
      debug: false,
    });
  }

  if (process.env.NEXT_RUNTIME === "edge") {
    Sentry.init({
      dsn: process.env.SENTRY_DSN || "https://0370d698d70eacab62830dd0115a1174@o4511590911836160.ingest.us.sentry.io/4511694272069632",
      tracesSampleRate: 1.0,
      debug: false,
    });
  }
}
