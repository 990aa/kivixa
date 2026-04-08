"use client";

import type { ReleaseData } from "@/lib/github";
import { useLenis } from "@/hooks/useLenis";
import HeroCurtain from "./HeroCurtain";
import AppRiseMockup from "./AppRiseMockup";
import FeatureCards from "./FeatureCards";
import AIModelShowcase from "./AIModelShowcase";
import PrivacyVault from "./PrivacyVault";
import PlatformGrid from "./PlatformGrid";
import FooterCTA from "./FooterCTA";

interface LandingExperienceProps {
  release: ReleaseData;
}

export default function LandingExperience({ release }: LandingExperienceProps) {
  useLenis();

  return (
    <main className="cinematic-journey">
      <HeroCurtain release={release} />
      <AppRiseMockup />
      <FeatureCards />
      <AIModelShowcase />
      <PrivacyVault />
      <PlatformGrid release={release} />
      <FooterCTA release={release} />
    </main>
  );
}
