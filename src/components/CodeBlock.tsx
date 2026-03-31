"use client";

interface CodeBlockProps {
  title: string;
  lines: Array<{ content: string; className?: string }>;
}

export default function CodeBlock({ title, lines }: CodeBlockProps) {
  return (
    <div className="code-block">
      <div className="code-block-header">
        <span className="code-block-dot bg-accent-rose/60" />
        <span className="code-block-dot bg-accent-amber/60" />
        <span className="code-block-dot bg-accent-teal/60" />
        <span className="ml-2 text-xs text-text-muted font-mono">{title}</span>
      </div>
      <pre tabIndex={0} role="region" aria-label={`${title} code`}>
        {lines.map((line, i) => (
          <div key={i}>
            <span className={line.className || ""}>{line.content}</span>
          </div>
        ))}
      </pre>
    </div>
  );
}
