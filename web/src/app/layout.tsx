import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <title>RentLanka Admin — Platform Operations</title>
        <meta name="description" content="Internal operations dashboard for RentLanka." />
      </head>
      <body
        suppressHydrationWarning
        className={`${inter.variable} min-h-screen bg-slate-950 text-slate-50 antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
