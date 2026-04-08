"use client";

import { PropsWithChildren } from "react";
import { useLenis } from "@/hooks/useLenis";

export default function LenisProvider({ children }: PropsWithChildren) {
  useLenis();
  return <>{children}</>;
}
