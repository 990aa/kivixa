'use client';

import { Icon } from "@/components/icons";
import { useState } from "react";
import { motion } from "framer-motion";
import Link from "next/link";

export default function EditorPage({ params }: { params: { id: string } }) {
  const [isLeftSidebarOpen, setIsLeftSidebarOpen] = useState(true);
  const [isRightSidebarOpen, setIsRightSidebarOpen] = useState(true);

  return (
    <div className="grid h-full w-full grid-rows-[auto_1fr] overflow-hidden bg-muted/20">
      <header className="flex items-center justify-between border-b bg-background p-2">
        <div className="flex items-center gap-2">
          <Link href="/library">
            <button className="p-2">
              <Icon name="arrowLeft" className="h-5 w-5" />
            </button>
          </Link>
          <h1 className="text-lg font-bold">Note Title</h1>
        </div>
        <div className="flex items-center gap-2">
          <button className="p-2">
            <Icon name="share" className="h-5 w-5" />
          </button>
          <button className="p-2">
            <Icon name="moreVertical" className="h-5 w-5" />
          </button>
        </div>
      </header>
      <div className="grid grid-cols-[auto_1fr_auto] overflow-hidden">
        <motion.aside
          initial={{ width: 256 }} animate={{ width: isLeftSidebarOpen ? 256 : 0, padding: isLeftSidebarOpen ? '1rem' : 0 }}
          className="overflow-hidden border-r bg-background"
        >
          <h2 className="text-lg font-semibold">Left Sidebar</h2>
        </motion.aside>
        <main className="relative flex flex-col">
          <motion.div drag dragMomentum={false} className="absolute top-2 right-2 z-10">
            <div className="flex items-center gap-2 rounded-lg border bg-background p-2 shadow-md">
                <Icon name="gripVertical" className="cursor-move" />
              <button className="p-2">
                <Icon name="bold" className="h-5 w-5" />
              </button>
              <button className="p-2">
                <Icon name="italic" className="h-5 w-5" />
              </button>
              <button className="p-2">
                <Icon name="underline" className="h-5 w-5" />
              </button>
              <button className="p-2">
                <Icon name="strikethrough" className="h-5 w-5" />
              </button>
              <button className="p-2">
                <Icon name="code" className="h-5 w-5" />
              </button>
            </div>
          </motion.div>
          <div className="flex-grow p-4">Editor Content</div>
          <button onClick={() => setIsLeftSidebarOpen(!isLeftSidebarOpen)} className="absolute top-1/2 -translate-y-1/2 -left-0.5 bg-background border rounded-full p-0.5">
            <Icon name={isLeftSidebarOpen ? 'arrowLeft' : 'arrowRight'} className="h-4 w-4" />
          </button>
          <button onClick={() => setIsRightSidebarOpen(!isRightSidebarOpen)} className="absolute top-1/2 -translate-y-1/2 -right-0.5 bg-background border rounded-full p-0.5">
            <Icon name={isRightSidebarOpen ? 'arrowRight' : 'arrowLeft'} className="h-4 w-4" />
          </button>
        </main>
        <motion.aside
          initial={{ width: 256 }} animate={{ width: isRightSidebarOpen ? 256 : 0, padding: isRightSidebarOpen ? '1rem' : 0 }}
          className="overflow-hidden border-l bg-background"
        >
          <h2 className="text-lg font-semibold">Right Sidebar</h2>
        </motion.aside>
      </div>
    </div>
  );
}
