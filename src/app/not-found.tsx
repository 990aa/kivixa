import Link from "next/link";
import { Home } from "lucide-react";

export default function NotFound() {
  return (
    <main className="relative flex min-h-screen items-center justify-center overflow-hidden px-5 py-20 text-slate-100">
      <div className="pointer-events-none absolute inset-0 opacity-70 [background:radial-gradient(circle_at_18%_12%,rgba(82,212,197,0.2),transparent_38%),radial-gradient(circle_at_82%_14%,rgba(143,196,255,0.18),transparent_36%),linear-gradient(180deg,#0c1a2b_0%,#07111d_100%)]" />

      <section className="glass-panel relative z-10 mx-auto w-full max-w-2xl rounded-[2rem] p-8 text-center sm:p-11">
        <p className="kicker">Route Not Found</p>
        <h1 className="display-title mt-4 text-5xl text-white sm:text-6xl">404</h1>
        <p className="lead-copy mt-5 text-lg text-slate-100 sm:text-xl">This page does not exist in the current Kivixa web experience.</p>
        <p className="caption-tight mx-auto mt-3 max-w-xl text-sm sm:text-base">
          The website currently ships a single primary route. Use the link below to go back to the landing page.
        </p>

        <Link
          href="/"
          className="mt-8 inline-flex items-center justify-center gap-2 rounded-full border border-cyan-200/45 bg-gradient-to-r from-cyan-500 via-sky-500 to-blue-500 px-6 py-3 text-sm font-semibold text-white shadow-[0_16px_50px_rgba(2,132,199,0.45)] hover:-translate-y-0.5"
        >
          <Home size={18} />
          Back to Home
        </Link>
      </section>
    </main>
  );
}
