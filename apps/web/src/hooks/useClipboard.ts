
import { useState, useCallback } from 'react';

export function useClipboard<T>() {
  const [clipboard, setClipboard] = useState<T | null>(null);

  const copy = useCallback((data: T) => {
    setClipboard(data);
  }, []);

  const paste = useCallback(() => {
    return clipboard;
  }, [clipboard]);

  return { copy, paste };
}
