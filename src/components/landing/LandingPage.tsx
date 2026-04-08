import type { ReleaseData } from "@/lib/github";
import HeroSection from "./HeroSection";
import AppMockupSection from "./AppMockupSection";
import FeatureGridSection from "./FeatureGridSection";
import AIModelsSection from "./AIModelsSection";
import PrivacySection from "./PrivacySection";
import DownloadsSection from "./DownloadsSection";
import FooterCTA from "./FooterCTA";

interface LandingPageProps {
  release: ReleaseData;
}

export default function LandingPage({ release }: LandingPageProps) {
  return (
    <main className="landing-journey">
      <HeroSection release={release} />
      <AppMockupSection />
      <FeatureGridSection />
      <AIModelsSection />
      <PrivacySection />
      <DownloadsSection release={release} />
      <FooterCTA release={release} />
    </main>
  );
}
