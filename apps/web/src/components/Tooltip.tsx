
import React from 'react';

export function Tooltip({ children, text }: { children: React.ReactNode, text: string }) {
  return (
    <div className="relative group">
      {children}
      <div className="absolute bottom-full mb-2 hidden group-hover:block w-max bg-gray-800 text-white text-xs rounded-md p-2">
        {text}
      </div>
    </div>
  );
}
