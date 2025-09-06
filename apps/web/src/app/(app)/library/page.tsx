import { Icon } from "@/components/icons";
import Link from "next/link";

const notebooks = [
  { id: 1, name: "My First Notebook", type: "notebook" },
  { id: 2, name: "Work Documents", type: "folder" },
  { id: 3, name: "Personal Projects", type: "folder" },
  { id: 4, name: "Quick Notes", type: "notebook" },
];

export default function LibraryPage() {
  return (
    <div className="h-full w-full p-4">
      <header className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Library</h1>
        <div className="flex items-center gap-2">
          <button className="p-2">
            <Icon name="search" className="h-5 w-5" />
          </button>
          <button className="p-2">
            <Icon name="settings" className="h-5 w-5" />
          </button>
        </div>
      </header>
      <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
        {notebooks.map((item) => (
          <Link key={item.id} href={item.type === "notebook" ? `/editor/${item.id}` : "#"}>
            <div className="flex flex-col items-center justify-center rounded-lg border p-4 shadow-sm transition-colors hover:bg-muted/50">
              <Icon name={item.type === "folder" ? "folder" : "notebook"} className="h-16 w-16" />
              <span className="mt-2 text-center">{item.name}</span>
            </div>
          </Link>
        ))}
      </div>
      <div className="absolute bottom-8 right-8">
        <div className="group relative">
          <div className="absolute bottom-20 right-0 hidden w-max flex-col items-start gap-2 group-hover:flex">
            <Link href="/editor/new">
              <button className="flex w-full items-center gap-2 rounded-full bg-background p-3 shadow-lg transition-colors hover:bg-muted/50">
                <Icon name="edit" className="h-5 w-5" />
                <span className="pr-2">New Note</span>
              </button>
            </Link>
            <Link href="/editor/new?quick=true">
              <button className="flex w-full items-center gap-2 rounded-full bg-background p-3 shadow-lg transition-colors hover:bg-muted/50">
                <Icon name="squarePen" className="h-5 w-5" />
                <span className="pr-2">Quick Note</span>
              </button>
            </Link>
            <button className="flex w-full items-center gap-2 rounded-full bg-background p-3 shadow-lg transition-colors hover:bg-muted/50">
              <Icon name="fileUp" className="h-5 w-5" />
              <span className="pr-2">Import</span>
            </button>
            <Link href="/editor/new?canvas=true">
              <button className="flex w-full items-center gap-2 rounded-full bg-background p-3 shadow-lg transition-colors hover:bg-muted/50">
                <Icon name="image" className="h-5 w-5" />
                <span className="pr-2">Infinite Canvas</span>
              </button>
            </Link>
          </div>
          <button className="flex h-16 w-16 items-center justify-center rounded-full bg-primary text-primary-foreground shadow-lg">
            <Icon name="plus" className="h-8 w-8" />
          </button>
        </div>
      </div>
    </div>
  );
}
