import React, { useState } from 'react'
import { Card } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { parseModelFormat } from '@/lib/spec-data'
import { Check, Warning } from '@phosphor-icons/react'

export function ModelValidator() {
  const [input, setInput] = useState('')
  const validation = parseModelFormat(input)

  return (
    <Card className="p-6">
      <div className="flex flex-col gap-4">
        <div className="flex flex-col gap-2">
          <Label htmlFor="model-input" className="text-base font-semibold">
            Model Format Validator
          </Label>
          <p className="text-sm text-muted-foreground">
            Test the provider:model parsing logic. Try examples like{' '}
            <code className="px-1.5 py-0.5 bg-muted rounded text-xs">openai:gpt-4o</code> or{' '}
            <code className="px-1.5 py-0.5 bg-muted rounded text-xs">claude-3-sonnet</code>
          </p>
        </div>

        <Input
          id="model-input"
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Enter model format..."
          className="font-mono"
        />

        {input && (
          <div className="flex flex-col gap-3 p-4 bg-muted/30 rounded-lg border border-border">
            <div className="flex items-center gap-2">
              {validation.valid ? (
                <>
                  <Check className="text-teal" weight="bold" size={20} />
                  <span className="text-sm font-semibold text-teal">Valid Format</span>
                </>
              ) : (
                <>
                  <Warning className="text-destructive" weight="bold" size={20} />
                  <span className="text-sm font-semibold text-destructive">Invalid Format</span>
                </>
              )}
            </div>

            {validation.valid ? (
              <div className="flex flex-col gap-2">
                <div className="flex items-center gap-2">
                  <span className="text-sm text-muted-foreground w-20">Provider:</span>
                  <Badge variant="secondary" className="font-mono">
                    {validation.provider}
                  </Badge>
                  {validation.provider === 'openai' && input.indexOf(':') === -1 && (
                    <span className="text-xs text-muted-foreground">(default)</span>
                  )}
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-sm text-muted-foreground w-20">Model:</span>
                  <Badge variant="outline" className="font-mono">
                    {validation.model}
                  </Badge>
                </div>
              </div>
            ) : (
              <p className="text-sm text-destructive">{validation.error}</p>
            )}
          </div>
        )}

        {!input && (
          <div className="p-4 bg-muted/30 rounded-lg border border-dashed border-border">
            <p className="text-sm text-muted-foreground text-center">
              Enter a model format above to see validation results
            </p>
          </div>
        )}
      </div>
    </Card>
  )
}
