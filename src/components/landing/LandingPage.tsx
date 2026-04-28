import type { ReleaseData } from "@/lib/github";
import HeroSection from "./HeroSection";
import AppMockupSection from "./AppMockupSection";
import FeatureGridSection from "./FeatureGridSection";
import AIModelsSection from "./AIModelsSection";
import PrivacySection from "./PrivacySection";
import DownloadsSection from "./DownloadsSection";
import FooterCTA from "./FooterCTA";
import ParticleCanvas from "./ParticleCanvas";

interface LandingPageProps {
  release: ReleaseData;
}

export default function LandingPage({ release }: LandingPageProps) {
  return (
    <>
      <ParticleCanvas className="fixed inset-0" count={100} />
      <main className="landing-journey relative z-10">
        <HeroSection release={release} />
        <AppMockupSection />
        <FeatureGridSection />
        <AIModelsSection />
        <PrivacySection />
        <DownloadsSection release={release} />
        <FooterCTA release={release} />
      </main>
    </>
  );
}
