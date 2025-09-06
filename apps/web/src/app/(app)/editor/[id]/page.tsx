'use client';

import { Icon } from "@/components/icons";
import { useState, useRef } from "react";
import { motion, PanInfo } from "framer-motion";
import Link from "next/link";

// Dummy data for document list
const documents = [
  { id: "note1", title: "Note 1" },
  { id: "note2", title: "Note 2" },
  { id: "note3", title: "Note 3" },
];

function EditorView({ noteId }: { noteId: string }) {
  // Dummy representation of pages
  const pages = [1, 2, 3];

  return (
    <div className="relative flex-grow p-4 overflow-y-auto">
      <motion.div drag dragMomentum={false} className="absolute top-2 right-2 z-10">
        <div className="flex items-center gap-2 rounded-lg border bg-background p-2 shadow-md">
          <Icon name="gripVertical" className="cursor-move" />
          <button className="p-2"><Icon name="bold" className="h-5 w-5" /></button>
          <button className="p-2"><Icon name="italic" className="h-5 w-5" /></button>
          <button className="p-2"><Icon name="underline" className="h-5 w-5" /></button>
          <button className="p-2"><Icon name="strikethrough" className="h-5 w-5" /></button>
          <button className="p-2"><Icon name="code" className="h-5 w-5" /></button>
        </div>
      </motion.div>
      <h2 className="text-xl font-bold mb-4">Editor for {noteId}</h2>
      {pages.map(page => (
        <div key={page} className="relative border-b-2 border-dashed mb-4 pb-4">
          <div className="absolute top-0 right-0">
            <div className="relative">
              <button className="p-2">
                <Icon name="moreVertical" className="h-5 w-5" />
              </button>
              <div className="absolute right-0 mt-2 w-48 bg-background border rounded-md shadow-lg z-10 hidden">
                <button className="block w-full text-left px-4 py-2 text-sm">Add to Outline</button>
                <button className="block w-full text-left px-4 py-2 text-sm">Add Note</button>
              </div>
            </div>
          </div>
          <p>This is page {page}.</p>
        </div>
      ))}
    </div>
  );
}

function RightSidebar() {
  const [activeTab, setActiveTab] = useState("thumbnails");

  return (
    <div className="flex flex-col h-full">
      <div className="flex-shrink-0 border-b">
        <button onClick={() => setActiveTab("thumbnails")} className={`px-4 py-2 ${activeTab === "thumbnails" ? "border-b-2 border-primary" : ""}`}>Thumbnails</button>
        <button onClick={() => setActiveTab("outline")} className={`px-4 py-2 ${activeTab === "outline" ? "border-b-2 border-primary" : ""}`}>Outline</button>
        <button onClick={() => setActiveTab("notes")} className={`px-4 py-2 ${activeTab === "notes" ? "border-b-2 border-primary" : ""}`}>Notes</button>
      </div>
      <div className="flex-grow overflow-y-auto p-4">
        {activeTab === "thumbnails" && <div>Page Thumbnails</div>}
        {activeTab === "outline" && <div>Outline</div>}
        {activeTab === "notes" && <div>Notes/Comments</div>}
      </div>
      <div className="flex-shrink-0 border-t p-4">
        <h3 className="text-lg font-semibold mb-2">Quick Settings</h3>
        {/* Quick Settings content */}
      </div>
    </div>
  );
}

export default function EditorPage({ params }: { params: { id: string } }) {
  const [isLeftSidebarOpen, setIsLeftSidebarOpen] = useState(true);
  const [isRightSidebarOpen, setIsRightSidebarOpen] = useState(true);
  const [isSplit, setIsSplit] = useState(false);
  const [splitOrientation, setSplitOrientation] = useState<"horizontal" | "vertical">("vertical");
  const [pane1, setPane1] = useState(params.id);
  const [pane2, setPane2] = useState<string | null>(null);

  const constraintsRef = useRef<HTMLDivElement>(null);

  const handleDrag = (event: MouseEvent | TouchEvent | PointerEvent, info: PanInfo) => {
    if (!constraintsRef.current) return;
    const containerRect = constraintsRef.current.getBoundingClientRect();
    if (splitOrientation === "vertical") {
      if (info.point.x < containerRect.left + 50) {
        setIsSplit(false);
        setPane2(null);
      } else if (info.point.x > containerRect.right - 50) {
        setIsSplit(false);
        setPane1(pane2!);
        setPane2(null);
      }
    } else {
      if (info.point.y < containerRect.top + 50) {
        setIsSplit(false);
        setPane2(null);
      } else if (info.point.y > containerRect.bottom - 50) {
        setIsSplit(false);
        setPane1(pane2!);
        setPane2(null);
      }
    }
  };

  const handleQuickSplit = (noteId: string) => {
    if (!isSplit) {
      setIsSplit(true);
      setPane2(noteId);
    } else {
      setPane2(noteId);
    }
  };

  return (
    <div className="grid h-full w-full grid-rows-[auto_1fr] overflow-hidden bg-muted/20">
      <header className="flex items-center justify-between border-b bg-background p-2">
        <div className="flex items-center gap-2">
          <Link href="/library"><button className="p-2"><Icon name="arrowLeft" className="h-5 w-5" /></button></Link>
          <h1 className="text-lg font-bold">Note Title</h1>
        </div>
        <div className="flex items-center gap-2">
          <button onClick={() => { if(isSplit) setPane2(null); setIsSplit(!isSplit); }} className="p-2">
            <Icon name={isSplit ? "layout-grid" : "layout-template"} className="h-5 w-5" />
          </button>
          {isSplit && (
            <>
              <button onClick={() => setSplitOrientation(splitOrientation === "vertical" ? "horizontal" : "vertical")} className="p-2">
                <Icon name={splitOrientation === "vertical" ? "columns" : "rows"} className="h-5 w-5" />
              </button>
              <button onClick={() => { if(pane2) { const temp = pane1; setPane1(pane2); setPane2(temp); } }} className="p-2">
                <Icon name="replace" className="h-5 w-5" />
              </button>
            </>
          )}
          <button className="p-2"><Icon name="share" className="h-5 w-5" /></button>
          <button className="p-2"><Icon name="moreVertical" className="h-5 w-5" /></button>
        </div>
      </header>
      <div className="grid grid-cols-[auto_1fr_auto] overflow-hidden">
        <motion.aside
          initial={{ width: 256 }} animate={{ width: isLeftSidebarOpen ? 256 : 0, padding: isLeftSidebarOpen ? '1rem' : 0 }}
          className="overflow-hidden border-r bg-background"
        >
          <h2 className="text-lg font-semibold mb-4">Documents</h2>
          <ul>
            {documents.map(doc => (
              <li key={doc.id} className="flex items-center justify-between">
                <Link href={`/editor/${doc.id}`} className="flex-grow p-2">{doc.title}</Link>
                <button onClick={() => handleQuickSplit(doc.id)} className="p-2">
                  <Icon name="split" className="h-5 w-5" />
                </button>
              </li>
            ))}
          </ul>
        </motion.aside>
        <main ref={constraintsRef} className="relative flex flex-col">
          {isSplit ? (
            <motion.div className={`flex h-full w-full ${splitOrientation === "vertical" ? "flex-row" : "flex-col"}`}>
              <div className="flex-1"><EditorView noteId={pane1} /></div>
              <motion.div
                drag={splitOrientation}
                onDragEnd={handleDrag}
                dragConstraints={constraintsRef}
                dragElastic={0.1}
                className={`cursor-col-resize relative ${splitOrientation === "vertical" ? "w-1.5" : "h-1.5"}`}
              >
                <div className={`bg-border h-full w-full`}></div>
              </motion.div>
              <div className="flex-1">{pane2 && <EditorView noteId={pane2} />}</div>
            </motion.div>
          ) : (
            <EditorView noteId={pane1} />
          )}
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
          <RightSidebar />
        </motion.aside>
      </div>
    </div>
  );
}
