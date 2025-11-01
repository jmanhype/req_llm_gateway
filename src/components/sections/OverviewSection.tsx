import React from 'react'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ArchitectureDiagram } from '@/components/ArchitectureDiagram'
import { Lightbulb, CheckCircle, XCircle } from '@phosphor-icons/react'

export function OverviewSection() {
  return (
    <div className="flex flex-col gap-6">
      <div>
        <h2 className="text-3xl font-bold mb-3">RecLLMGateway MVP</h2>
        <p className="text-lg text-muted-foreground leading-relaxed">
          An OpenAI-compatible LLM proxy with telemetry, usage tracking, and multi-provider routing for Elixir/Phoenix applications.
        </p>
      </div>

      <Alert className="border-primary/50 bg-primary/5">
        <Lightbulb className="text-primary" weight="duotone" size={20} />
        <AlertDescription className="text-sm">
          <strong>Key Design Decision:</strong> Use OpenAI Chat Completions as the industry standard format. 
          All major LLM gateways (LiteLLM, Kong AI, Apache APISIX) have converged on this format.
        </AlertDescription>
      </Alert>

      <div>
        <h3 className="text-xl font-semibold mb-3">Purpose</h3>
        <p className="text-muted-foreground leading-relaxed mb-3">
          Single OpenAI-compatible endpoint that:
        </p>
        <ul className="flex flex-col gap-2">
          <li className="flex items-start gap-2">
            <CheckCircle className="text-teal mt-1 flex-shrink-0" weight="fill" size={18} />
            <span className="text-foreground">Accepts standard OpenAI Chat Completions format</span>
          </li>
          <li className="flex items-start gap-2">
            <CheckCircle className="text-teal mt-1 flex-shrink-0" weight="fill" size={18} />
            <span className="text-foreground">Routes to multiple providers via <code className="px-1.5 py-0.5 bg-muted rounded text-sm font-mono">provider:model</code> syntax</span>
          </li>
          <li className="flex items-start gap-2">
            <CheckCircle className="text-teal mt-1 flex-shrink-0" weight="fill" size={18} />
            <span className="text-foreground">Emits telemetry events for observability</span>
          </li>
          <li className="flex items-start gap-2">
            <CheckCircle className="text-teal mt-1 flex-shrink-0" weight="fill" size={18} />
            <span className="text-foreground">Tracks usage in-memory with ETS</span>
          </li>
          <li className="flex items-start gap-2">
            <CheckCircle className="text-teal mt-1 flex-shrink-0" weight="fill" size={18} />
            <span className="text-foreground">Returns OpenAI-standard responses with optional extensions</span>
          </li>
        </ul>
      </div>

      <div>
        <h3 className="text-xl font-semibold mb-4">Architecture</h3>
        <Card className="p-6 bg-gradient-to-br from-background to-muted/20">
          <ArchitectureDiagram />
        </Card>
      </div>

      <div>
        <h3 className="text-xl font-semibold mb-3">Non-Goals for MVP</h3>
        <ul className="flex flex-col gap-2">
          <li className="flex items-start gap-2">
            <XCircle className="text-muted-foreground mt-1 flex-shrink-0" weight="fill" size={18} />
            <span className="text-muted-foreground">Persistence beyond process lifetime</span>
          </li>
          <li className="flex items-start gap-2">
            <XCircle className="text-muted-foreground mt-1 flex-shrink-0" weight="fill" size={18} />
            <span className="text-muted-foreground">Rate limiting</span>
          </li>
          <li className="flex items-start gap-2">
            <XCircle className="text-muted-foreground mt-1 flex-shrink-0" weight="fill" size={18} />
            <span className="text-muted-foreground">Provider authentication management</span>
          </li>
          <li className="flex items-start gap-2">
            <XCircle className="text-muted-foreground mt-1 flex-shrink-0" weight="fill" size={18} />
            <span className="text-muted-foreground">Full streaming support</span>
          </li>
          <li className="flex items-start gap-2">
            <XCircle className="text-muted-foreground mt-1 flex-shrink-0" weight="fill" size={18} />
            <span className="text-muted-foreground">Request/response transformation beyond provider routing</span>
          </li>
        </ul>
      </div>

      <div>
        <h3 className="text-xl font-semibold mb-4">Package Info</h3>
        <div className="flex flex-wrap gap-2">
          <Badge variant="secondary" className="text-sm">rec_llm_gateway</Badge>
          <Badge variant="outline" className="text-sm">Elixir/Phoenix</Badge>
          <Badge variant="outline" className="text-sm">OpenAI Compatible</Badge>
        </div>
      </div>
    </div>
  )
}
