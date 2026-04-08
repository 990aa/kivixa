import LandingPage from "@/components/landing/LandingPage";
import { getLatestRelease } from "@/lib/github";

export default async function Home() {
  const release = await getLatestRelease();

  return <LandingPage release={release} />;
}
