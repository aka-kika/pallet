import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Pallet | Your color collection",
  description: "Extract colors from images. Collect palettes, rotate the main color, and export light and dark themes.",
  icons: {
    icon: "/favicon.png",
    shortcut: "/favicon.png",
    apple: "/favicon.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
