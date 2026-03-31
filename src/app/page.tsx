import Navbar from "@/components/Navbar";
import Hero from "@/components/Hero";
import TechStrip from "@/components/TechStrip";
import Features from "@/components/Features";
import AISection from "@/components/AISection";
import PlatformGrid from "@/components/PlatformGrid";
import DownloadSection from "@/components/DownloadSection";
import Footer from "@/components/Footer";
import { getLatestRelease } from "@/lib/github";

export default async function Home() {
  const release = await getLatestRelease();

  return (
    <>
      <Navbar />
      <main>
        <Hero release={release} />
        <TechStrip />
        <Features />
        <AISection />
        <PlatformGrid />
        <DownloadSection release={release} />
      </main>
      <Footer version={release.version} />
    </>
  );
}
