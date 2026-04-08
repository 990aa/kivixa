import type { Metadata } from "next";
import { IBM_Plex_Mono, Space_Grotesk } from "next/font/google";
import LenisProvider from "@/components/landing/LenisProvider";
import "./globals.css";

const spaceGrotesk = Space_Grotesk({
  variable: "--font-space-grotesk",
  subsets: ["latin"],
  display: "swap",
});

const ibmPlexMono = IBM_Plex_Mono({
  variable: "--font-ibm-plex-mono",
  weight: ["400", "500", "600"],
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
    icon: [
      { url: "/assets/icon.png", type: "image/png", sizes: "512x512" },
    ],
    shortcut: "/assets/icon.png",
    apple: "/assets/icon.png",
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
      className={`${spaceGrotesk.variable} ${ibmPlexMono.variable}`}
    >
      <body>
        <LenisProvider>{children}</LenisProvider>
      </body>
    </html>
  );
}
