
'use client';

import { useState, useEffect } from 'react';
import { Icon } from './icons';
import { Reorder } from 'framer-motion';
import { useClipboard } from '@/hooks/useClipboard';
import { Tooltip } from './Tooltip';

// Dummy data based on kivixa.json format
const dummyPages = [
  { id: 'page-1', title: 'Page 1', layers: [] },
  { id: 'page-2', title: 'Page 2', layers: [] },
  { id: 'page-3', title: 'Page 3', layers: [] },
  { id: 'page-4', title: 'Page 4', layers: [] },
  { id: 'page-5', title: 'Page 5', layers: [] },
  { id: 'page-6', title: 'Page 6', layers: [] },
];

export function PageThumbnails() {
  const [pages, setPages] = useState(dummyPages);
  const [selectedPages, setSelectedPages] = useState<Set<string>>(new Set());
  const { copy, paste } = useClipboard<any[]>();

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.ctrlKey || e.metaKey) {
        if (e.key === 'c') {
          const pagesToCopy = pages.filter(p => selectedPages.has(p.id));
          copy(pagesToCopy);
        }
        if (e.key === 'v') {
          const pastedPages = paste();
          if (pastedPages) {
            const newPages = pastedPages.map(p => ({ ...p, id: `page-${Math.random()}` }));
            setPages([...pages, ...newPages]);
          }
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [selectedPages, pages, copy, paste]);

  const handleSelectPage = (pageId: string, e: React.MouseEvent) => {
    const newSelectedPages = new Set(selectedPages);
    if (e.ctrlKey || e.metaKey) {
      if (newSelectedPages.has(pageId)) {
        newSelectedPages.delete(pageId);
      } else {
        newSelectedPages.add(pageId);
      }
    } else if (e.shiftKey) {
      const lastSelected = Array.from(selectedPages).pop();
      if (lastSelected) {
        const lastIndex = pages.findIndex(p => p.id === lastSelected);
        const currentIndex = pages.findIndex(p => p.id === pageId);
        const start = Math.min(lastIndex, currentIndex);
        const end = Math.max(lastIndex, currentIndex);
        for (let i = start; i <= end; i++) {
          newSelectedPages.add(pages[i].id);
        }
      } else {
        newSelectedPages.add(pageId);
      }
    } else {
      if (newSelectedPages.has(pageId) && newSelectedPages.size === 1) {
        newSelectedPages.clear();
      } else {
        newSelectedPages.clear();
        newSelectedPages.add(pageId);
      }
    }
    setSelectedPages(newSelectedPages);
  };

  const addPage = () => {
    const newPage = {
      id: `page-${pages.length + 1}`,
      title: `Page ${pages.length + 1}`,
      layers: [],
    };
    setPages([...pages, newPage]);
  };

  const deleteSelectedPages = () => {
    setPages(pages.filter(p => !selectedPages.has(p.id)));
    setSelectedPages(new Set());
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-2">
        <h3 className="text-lg font-semibold">Pages</h3>
        <div className="flex items-center gap-2">
          <button onClick={addPage} className="p-2">
            <Icon name="plus" className="h-5 w-5" />
          </button>
          <button onClick={deleteSelectedPages} disabled={selectedPages.size === 0} className="p-2 disabled:opacity-50">
            <Icon name="trash" className="h-5 w-5" />
          </button>
          <Tooltip text="Merge (coming soon)">
            <button disabled className="p-2 disabled:opacity-50">
              <Icon name="merge" className="h-5 w-5" />
            </button>
          </Tooltip>
          <Tooltip text="Split (coming soon)">
            <button disabled className="p-2 disabled:opacity-50">
              <Icon name="split" className="h-5 w-5" />
            </button>
          </Tooltip>
        </div>
      </div>
      <Reorder.Group axis="y" values={pages} onReorder={setPages} className="grid grid-cols-2 gap-2">
        {pages.map((page, index) => (
          <Reorder.Item key={page.id} value={page}>
            <div
              onClick={(e) => handleSelectPage(page.id, e)}
              className={`relative rounded-lg border p-2 cursor-pointer ${selectedPages.has(page.id) ? 'border-primary' : ''}`}
            >
              <div className="aspect-[3/4] bg-muted/50 rounded-md flex items-center justify-center">
                <span className="text-sm text-muted-foreground">{page.title}</span>
              </div>
              <div className="text-center text-xs mt-1">{index + 1}</div>
            </div>
          </Reorder.Item>
        ))}
      </Reorder.Group>
    </div>
  );
}
