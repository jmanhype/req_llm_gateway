import React from 'react'
import { ComponentCard } from '@/components/ComponentCard'
import { components } from '@/lib/spec-data'

export function ComponentsSection() {
  return (
    <div className="flex flex-col gap-6">
      <div>
        <h2 className="text-3xl font-bold mb-3">Core Components</h2>
        <p className="text-lg text-muted-foreground">
          Six Elixir modules that power the gateway functionality
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        {components.map((component) => (
          <ComponentCard key={component.file} component={component} />
        ))}
      </div>

      <div className="mt-4">
        <h3 className="text-xl font-semibold mb-3">Package Structure</h3>
        <pre className="p-4 bg-card rounded-lg border border-border overflow-x-auto">
          <code className="text-sm font-mono text-foreground">{`lib/
  rec_llm_gateway/
    application.ex        # OTP application & supervisor
    plug.ex              # Main endpoint handler
    usage.ex             # ETS-backed usage counters
    telemetry.ex         # Telemetry event helpers
    dashboard_page.ex    # Phoenix LiveDashboard page
    model_parser.ex      # Parse provider:model syntax
    pricing.ex           # Optional cost calculator

test/
  rec_llm_gateway/
    plug_test.exs
    usage_test.exs
    model_parser_test.exs

mix.exs
README.md`}</code>
        </pre>
      </div>
    </div>
  )
}
