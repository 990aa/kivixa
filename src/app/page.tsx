import LandingExperience from "@/components/LandingExperience";
import { getLatestRelease } from "@/lib/github";

export default async function Home() {
  const release = await getLatestRelease();

  return <LandingExperience release={release} />;
}
