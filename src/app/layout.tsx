import type { Metadata } from "next";
import { Inter, JetBrains_Mono } from "next/font/google";
import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  display: "swap",
});

const jetBrainsMono = JetBrains_Mono({
  variable: "--font-jetbrains-mono",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL("https://kivixa.dev"),
  title: "Kivixa — Privacy-First Productivity Workspace with On-Device AI",
  description:
    "A local-first, cross-platform workspace for notes, sketching, planning, and private AI assistance. Your data never leaves your device.",
  openGraph: {
    title: "Kivixa — Privacy-First Productivity Workspace",
    description:
      "Notes, sketching, planning, and on-device AI — all local, all private, all yours.",
    images: [{ url: "/assets/icon.png", width: 512, height: 512 }],
    type: "website",
  },
  icons: {
    icon: "/assets/icon.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${inter.variable} ${jetBrainsMono.variable}`}
    >
      <body>{children}</body>
    </html>
  );
}
