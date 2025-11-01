import { Card } from '@/components/ui/card'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Copy, Check } from '@phosphor-icons/react'
import { useState } from 'react'
import { toast } from 'sonner'

interface CodeBlockProps {
  code: string
  language: string
  title?: string
}

export function CodeBlock({ code, language, title }: CodeBlockProps) {
  const [copied, setCopied] = useState(false)

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(code)
      setCopied(true)
      toast.success('Copied to clipboard')
      setTimeout(() => setCopied(false), 2000)
    } catch {
      toast.error('Failed to copy')
    }
  }

  return (
    <Card className="overflow-hidden bg-card">
      {title && (
        <div className="flex items-center justify-between border-b border-border px-4 py-2 bg-muted/50">
          <span className="text-sm font-medium text-muted-foreground uppercase tracking-wide">
            {title}
          </span>
        </div>
      )}
      <div className="relative group">
        <ScrollArea className="w-full">
          <pre className="p-4 text-sm overflow-x-auto">
            <code className="text-foreground font-mono">{code}</code>
          </pre>
        </ScrollArea>
        <button
          onClick={handleCopy}
          className="absolute top-2 right-2 p-2 rounded-lg bg-background/80 backdrop-blur-sm border border-border opacity-0 group-hover:opacity-100 transition-opacity hover:bg-muted"
        >
          {copied ? (
            <Check className="text-teal" weight="bold" />
          ) : (
            <Copy className="text-muted-foreground" />
          )}
        </button>
      </div>
    </Card>
  )
}
