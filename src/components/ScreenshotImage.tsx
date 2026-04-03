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
    <img
      src={src}
      alt={alt}
      width={width}
      height={height}
      loading={loading}
      decoding="async"
      data-screenshot="true"
      className={`mx-auto block h-auto w-full object-contain screenshot-image ${className}`}
      style={{ maxWidth: `${width}px` }}
    />
  );
}