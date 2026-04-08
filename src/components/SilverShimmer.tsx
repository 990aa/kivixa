import { ReactNode } from "react";

interface SilverShimmerProps {
  className?: string;
  innerClassName?: string;
  children: ReactNode;
}

export default function SilverShimmer({
  className = "",
  innerClassName = "",
  children,
}: SilverShimmerProps) {
  return (
    <div className={`silver-shimmer ${className}`}>
      <div className={`silver-shimmer-inner ${innerClassName}`}>{children}</div>
    </div>
  );
}
