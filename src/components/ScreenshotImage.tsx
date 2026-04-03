interface ScreenshotImageProps {
  src: string;
  alt: string;
  width: number;
  height: number;
  className?: string;
  loading?: "eager" | "lazy";
}

export default function ScreenshotImage({
  src,
  alt,
  width,
  height,
  className = "",
  loading = "lazy",
}: ScreenshotImageProps) {
  return (
    // Intentional plain img usage to preserve source screenshot fidelity.
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={src}
      alt={alt}
      width={width}
      height={height}
      loading={loading}
      decoding="async"
      data-screenshot="true"
      className={`mx-auto block h-auto max-w-full object-contain screenshot-image ${className}`}
    />
  );
}