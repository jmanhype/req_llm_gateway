import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { CodeBlock } from '@/components/CodeBlock'
import { ModelValidator } from '@/components/ModelValidator'
import { requestExample, responseExample } from '@/lib/spec-data'
import { Separator } from '@/components/ui/separator'

export function APISection() {
  return (
    <div className="flex flex-col gap-6">
      <div>
        <h2 className="text-3xl font-bold mb-3">API Contract</h2>
        <p className="text-lg text-muted-foreground">
          OpenAI-compatible endpoint specification with multi-provider routing
        </p>
      </div>

      <div>
        <h3 className="text-xl font-semibold mb-3">Endpoint</h3>
        <Card className="p-4 bg-muted/30">
          <div className="flex items-center gap-3">
            <Badge className="bg-teal text-teal-foreground">POST</Badge>
            <code className="text-base font-mono font-semibold">/v1/chat/completions</code>
          </div>
        </Card>
      </div>

      <div>
        <h3 className="text-xl font-semibold mb-3">Model Routing</h3>
        <p className="text-muted-foreground mb-4 leading-relaxed">
          Use <code className="px-1.5 py-0.5 bg-muted rounded text-sm font-mono">provider:model</code> format following req_llm conventions:
        </p>
        
        <div className="grid gap-3 mb-4">
          <Card className="p-4">
            <div className="flex flex-col gap-2">
              <code className="font-mono text-sm font-semibold">"openai:gpt-4o-mini"</code>
              <p className="text-sm text-muted-foreground">→ Routes to OpenAI provider</p>
            </div>
          </Card>
          <Card className="p-4">
            <div className="flex flex-col gap-2">
              <code className="font-mono text-sm font-semibold">"anthropic:claude-3-sonnet-20240229"</code>
              <p className="text-sm text-muted-foreground">→ Routes to Anthropic provider</p>
            </div>
          </Card>
          <Card className="p-4">
            <div className="flex flex-col gap-2">
              <code className="font-mono text-sm font-semibold">"gpt-4o-mini"</code>
              <p className="text-sm text-muted-foreground">→ Uses default provider (configurable, defaults to OpenAI)</p>
            </div>
          </Card>
        </div>

        <ModelValidator />
      </div>

      <Separator />

      <div>
        <h3 className="text-xl font-semibold mb-3">Request Format</h3>
        <p className="text-muted-foreground mb-4">
          Standard OpenAI Chat Completions format with provider routing
        </p>
        <CodeBlock
          code={requestExample}
          language="json"
          title="Example Request"
        />
      </div>

      <div>
        <h3 className="text-xl font-semibold mb-3">Supported Parameters</h3>
        <div className="grid gap-2">
          {[
            { name: 'messages', required: true, desc: 'Array of message objects' },
            { name: 'model', required: true, desc: 'Model identifier with optional provider prefix' },
            { name: 'temperature', required: false, desc: 'Sampling temperature (0-2)' },
            { name: 'max_tokens', required: false, desc: 'Maximum completion tokens' },
            { name: 'top_p', required: false, desc: 'Nucleus sampling parameter' },
            { name: 'frequency_penalty', required: false, desc: 'Penalize frequent tokens' },
            { name: 'presence_penalty', required: false, desc: 'Penalize existing tokens' },
            { name: 'stop', required: false, desc: 'Stop sequences' },
            { name: 'stream', required: false, desc: 'Enable streaming (MVP: false only)' },
            { name: 'tools', required: false, desc: 'Tool/function definitions' },
            { name: 'tool_choice', required: false, desc: 'Tool selection strategy' },
          ].map((param) => (
            <Card key={param.name} className="p-3">
              <div className="flex items-start gap-3">
                <code className="font-mono text-sm font-semibold min-w-[140px]">{param.name}</code>
                {param.required && <Badge variant="destructive" className="text-xs">Required</Badge>}
                <p className="text-sm text-muted-foreground">{param.desc}</p>
              </div>
            </Card>
          ))}
        </div>
      </div>

      <Separator />

      <div>
        <h3 className="text-xl font-semibold mb-3">Response Format</h3>
        <p className="text-muted-foreground mb-4">
          OpenAI-standard response with optional <code className="px-1.5 py-0.5 bg-muted rounded text-sm font-mono">x_rec_llm</code> extensions
        </p>
        <CodeBlock
          code={responseExample}
          language="json"
          title="Example Response"
        />
      </div>

      <div>
        <h3 className="text-xl font-semibold mb-3">Extension Fields</h3>
        <p className="text-muted-foreground mb-4">
          Custom gateway metadata in <code className="px-1.5 py-0.5 bg-muted rounded text-sm font-mono">x_rec_llm</code> object (optional, can be disabled):
        </p>
        <div className="grid gap-2">
          {[
            { field: 'provider', desc: 'Actual provider used' },
            { field: 'latency_ms', desc: 'Request duration in milliseconds' },
            { field: 'cost_usd', desc: 'Estimated cost in USD (if pricing configured)' },
          ].map((field) => (
            <Card key={field.field} className="p-3">
              <div className="flex items-start gap-3">
                <code className="font-mono text-sm font-semibold min-w-[120px]">{field.field}</code>
                <p className="text-sm text-muted-foreground">{field.desc}</p>
              </div>
            </Card>
          ))}
        </div>
      </div>
    </div>
  )
}
