import Link from "next/link";

export default function NotFound() {
  return (
    <main className="relative flex min-h-screen items-center justify-center overflow-hidden px-6 py-20">
      <div className="absolute inset-0 -z-10">
        <div className="absolute top-1/3 left-1/2 h-[500px] w-[500px] -translate-x-1/2 rounded-full bg-silver-accent/10 blur-[120px]" />
      </div>

      <section className="mx-auto w-full max-w-lg rounded-2xl border border-silver-700/80 bg-silver-900/65 p-10 text-center backdrop-blur-md">
        <p className="mb-4 text-xs font-mono uppercase tracking-[0.2em] text-silver-accent">
          Route Not Found
        </p>
        <h1 className="mb-4 text-6xl font-semibold tracking-tight text-text-primary">404</h1>
        <p className="mb-2 text-lg text-text-secondary">
          This page does not exist.
        </p>
        <p className="mb-8 text-sm text-text-muted">
          Use the link below to return to the landing page.
        </p>

        <Link
          href="/"
          className="silver-button silver-button-primary inline-flex items-center gap-2"
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
            <polyline points="9 22 9 12 15 12 15 22" />
          </svg>
          Back to Home
        </Link>
      </section>
    </main>
  );
}
