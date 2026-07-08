'use client';

import * as Sentry from '@sentry/nextjs';
import { useEffect } from 'react';

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    Sentry.captureException(error);
  }, [error]);

  return (
    <html>
      <body className="bg-slate-950 text-slate-100 min-h-screen flex items-center justify-center">
        <div className="flex flex-col items-center justify-center p-6 text-center max-w-md">
          <div className="w-12 h-12 rounded-full bg-rose-500/10 border border-rose-500/20 flex items-center justify-center text-rose-400 mb-4">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          </div>
          <h2 className="text-lg font-bold text-slate-100">Critical Error Encountered</h2>
          <p className="text-xs text-slate-400 mt-2 leading-relaxed">
            A fatal error has occurred in the application. The administrator has been notified.
          </p>
          <button
            onClick={() => reset()}
            className="mt-6 px-5 py-2.5 bg-indigo-600 hover:bg-indigo-500 transition rounded-xl text-xs font-bold text-white shadow-lg shadow-indigo-500/15 cursor-pointer"
          >
            Refresh Interface
          </button>
        </div>
      </body>
    </html>
  );
}
