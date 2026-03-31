"use client";

import Image from "next/image";
import { motion } from "framer-motion";
import { Download, Smartphone, BrainCircuit, FileCode2, MonitorSmartphone, Github } from "lucide-react";

export default function Home() {
  const fadeUp = {
    hidden: { opacity: 0, y: 30 },
    visible: { opacity: 1, y: 0, transition: { duration: 0.8, ease: "easeOut" } }
  };

  return (
    <main className="min-h-screen bg-[#0B1120] selection:bg-purple-500/30">
      {/* --- HERO SECTION --- */}
      <section className="relative flex flex-col items-center justify-center min-h-screen px-4 overflow-hidden">
        {/* Background Glowing Orbs */}
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-purple-600/20 rounded-full blur-[120px] pointer-events-none" />
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-teal-500/10 rounded-full blur-[120px] pointer-events-none" />

        <motion.div 
          initial="hidden" 
          animate="visible" 
          variants={fadeUp}
          className="z-10 flex flex-col items-center text-center max-w-3xl"
        >
          <div className="mb-8 relative w-32 h-32">
            {/* Make sure your icon.png is in the public/assets folder! */}
            <Image src="/assets/icon.png" alt="Kivixa Logo" fill className="object-contain drop-shadow-[0_0_30px_rgba(168,85,247,0.4)]" />
          </div>
          
          <h1 className="text-6xl md:text-8xl font-bold tracking-tight mb-6 bg-gradient-to-br from-white via-slate-200 to-slate-500 bg-clip-text text-transparent">
            Kivixa
          </h1>
          <p className="text-xl md:text-2xl text-slate-400 mb-10 max-w-2xl">
            Intelligent Notes. Absolute Privacy. <br className="hidden md:block"/> Powered entirely by on-device AI.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 w-full sm:w-auto">
            {/* Windows Download Button */}
            <a href="https://github.com/990aa/kivixa/releases/latest" target="_blank" rel="noreferrer" 
               className="flex items-center justify-center gap-2 px-8 py-4 rounded-full bg-purple-600 hover:bg-purple-500 text-white font-medium transition-all shadow-[0_0_40px_rgba(147,51,234,0.4)] hover:shadow-[0_0_60px_rgba(147,51,234,0.6)] hover:-translate-y-1">
              <Download size={20} />
              Download for Windows
            </a>
            {/* Android Download Button */}
            <a href="https://kivixa.uptodown.com/android" target="_blank" rel="noreferrer" 
               className="flex items-center justify-center gap-2 px-8 py-4 rounded-full bg-[#111827] border border-slate-700 hover:border-teal-500/50 hover:bg-[#1F2937] text-slate-200 font-medium transition-all hover:-translate-y-1">
              <Smartphone size={20} />
              Get it on Uptodown
            </a>
          </div>
        </motion.div>
      </section>

      {/* --- FEATURES SECTION --- */}
      <section className="py-24 px-4 bg-[#070b14] relative z-10">
        <div className="max-w-6xl mx-auto">
          <motion.div 
            initial="hidden" whileInView="visible" viewport={{ once: true, margin: "-100px" }} variants={fadeUp}
            className="grid grid-cols-1 md:grid-cols-3 gap-8"
          >
            {/* Feature 1 */}
            <div className="p-8 rounded-3xl bg-slate-900/50 border border-slate-800 hover:border-purple-500/30 transition-colors">
              <div className="w-14 h-14 rounded-2xl bg-purple-500/10 flex items-center justify-center mb-6 text-purple-400">
                <BrainCircuit size={28} />
              </div>
              <h3 className="text-2xl font-semibold mb-3">On-Device AI</h3>
              <p className="text-slate-400 leading-relaxed">
                Interact with your notes using local language models. Zero cloud processing means your data never leaves your device.
              </p>
            </div>

            {/* Feature 2 */}
            <div className="p-8 rounded-3xl bg-slate-900/50 border border-slate-800 hover:border-teal-500/30 transition-colors">
              <div className="w-14 h-14 rounded-2xl bg-teal-500/10 flex items-center justify-center mb-6 text-teal-400">
                <FileCode2 size={28} />
              </div>
              <h3 className="text-2xl font-semibold mb-3">Markdown Native</h3>
              <p className="text-slate-400 leading-relaxed">
                Write flawlessly with full markdown support, code highlighting, and beautiful typography designed for focus.
              </p>
            </div>

            {/* Feature 3 */}
            <div className="p-8 rounded-3xl bg-slate-900/50 border border-slate-800 hover:border-blue-500/30 transition-colors">
              <div className="w-14 h-14 rounded-2xl bg-blue-500/10 flex items-center justify-center mb-6 text-blue-400">
                <MonitorSmartphone size={28} />
              </div>
              <h3 className="text-2xl font-semibold mb-3">Cross-Platform</h3>
              <p className="text-slate-400 leading-relaxed">
                Built from the ground up with Rust and Flutter to run blazingly fast on both Windows and Android.
              </p>
            </div>
          </motion.div>
        </div>
      </section>

      {/* --- SCREENSHOT SHOWCASE --- */}
      <section className="py-32 px-4 relative z-10 overflow-hidden">
        <div className="max-w-7xl mx-auto flex flex-col items-center">
          <motion.h2 
            initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeUp}
            className="text-4xl md:text-5xl font-bold text-center mb-16"
          >
            A workspace that <span className="text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-teal-400">gets out of your way.</span>
          </motion.h2>

          {/* Screenshot Grid. Note: You need to add screenshot1.png, etc to the public/assets folder later! */}
          <motion.div 
            initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeUp}
            className="grid grid-cols-1 md:grid-cols-3 gap-8 w-full"
          >
             <div className="relative w-full aspect-[9/19] rounded-3xl overflow-hidden border border-slate-800 shadow-2xl bg-slate-900 flex items-center justify-center">
                <span className="text-slate-600 text-sm">Drop screenshot1.png in /assets</span>
                {/* <Image src="/assets/screenshot1.png" alt="App UI" fill className="object-cover" /> */}
             </div>
             <div className="relative w-full aspect-[9/19] rounded-3xl overflow-hidden border border-slate-800 shadow-2xl bg-slate-900 md:-translate-y-8 flex items-center justify-center">
                <span className="text-slate-600 text-sm">Drop screenshot2.png in /assets</span>
                {/* <Image src="/assets/screenshot2.png" alt="App Editor" fill className="object-cover" /> */}
             </div>
             <div className="relative w-full aspect-[9/19] rounded-3xl overflow-hidden border border-slate-800 shadow-2xl bg-slate-900 flex items-center justify-center">
                <span className="text-slate-600 text-sm">Drop screenshot3.png in /assets</span>
                {/* <Image src="/assets/screenshot3.png" alt="AI Features" fill className="object-cover" /> */}
             </div>
          </motion.div>
        </div>
      </section>

      {/* --- FOOTER --- */}
      <footer className="py-12 border-t border-slate-800/50 bg-[#0B1120]">
        <div className="max-w-6xl mx-auto px-4 flex flex-col md:flex-row items-center justify-between opacity-60">
          <p className="text-sm">© {new Date().getFullYear()} Kivixa. Open Source under MIT License.</p>
          <a href="https://github.com/990aa/kivixa" target="_blank" rel="noreferrer" className="flex items-center gap-2 hover:text-white transition-colors mt-4 md:mt-0">
            <Github size={20} />
            View Source Code
          </a>
        </div>
      </footer>
    </main>
  );
}