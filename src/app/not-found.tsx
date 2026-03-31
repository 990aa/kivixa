import Link from "next/link";

export default function NotFound() {
  return (
    <main className="relative flex min-h-screen items-center justify-center overflow-hidden px-6 py-20">
      <div className="absolute inset-0 -z-10">
        <div className="absolute top-1/3 left-1/2 -translate-x-1/2 w-[500px] h-[500px] rounded-full bg-accent-primary/8 blur-[120px]" />
      </div>

      <section className="mx-auto w-full max-w-lg rounded-2xl border border-border-subtle bg-glass-bg backdrop-blur-md p-10 text-center">
        <p className="text-xs font-mono uppercase tracking-[0.2em] text-accent-teal mb-4">
          Route Not Found
        </p>
        <h1 className="text-6xl font-bold tracking-tight text-text-primary mb-4">404</h1>
        <p className="text-lg text-text-secondary mb-2">
          This page does not exist.
        </p>
        <p className="text-sm text-text-muted mb-8">
          Use the link below to return to the landing page.
        </p>

        <Link
          href="/"
          className="inline-flex items-center gap-2 rounded-xl bg-accent-primary px-6 py-3 text-sm font-semibold text-white hover:bg-accent-secondary transition-all shadow-glow-sm hover:shadow-glow-md hover:-translate-y-0.5"
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
