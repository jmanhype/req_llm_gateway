import { CodeBlock } from '@/components/CodeBlock'
import { Card } from '@/components/ui/card'
import { configExample, routerExample } from '@/lib/spec-data'

export function ConfigSection() {
  return (
    <div className="flex flex-col gap-6">
      <div>
        <h2 className="text-3xl font-bold mb-3">Configuration</h2>
        <p className="text-lg text-muted-foreground">
          Application configuration and integration setup
        </p>
      </div>

      <div>
        <h3 className="text-xl font-semibold mb-3">Application Config</h3>
        <CodeBlock
          code={configExample}
          language="elixir"
          title="config/config.exs"
        />
      </div>

      <div>
        <h3 className="text-xl font-semibold mb-3">Configuration Options</h3>
        <div className="grid gap-3">
          <Card className="p-4">
            <div className="flex flex-col gap-2">
              <code className="font-mono text-sm font-semibold">:default_provider</code>
              <p className="text-sm text-muted-foreground">
                Provider to use when model doesn't specify one (defaults to "openai")
              </p>
            </div>
          </Card>
          <Card className="p-4">
            <div className="flex flex-col gap-2">
              <code className="font-mono text-sm font-semibold">:include_extensions</code>
              <p className="text-sm text-muted-foreground">
                Include x_rec_llm metadata in responses (defaults to true)
              </p>
            </div>
          </Card>
          <Card className="p-4">
            <div className="flex flex-col gap-2">
              <code className="font-mono text-sm font-semibold">:pricing</code>
              <p className="text-sm text-muted-foreground">
                Optional map of model pricing for cost calculation (input/output per million tokens)
              </p>
            </div>
          </Card>
        </div>
      </div>

      <div>
        <h3 className="text-xl font-semibold mb-3">Router Integration</h3>
        <p className="text-muted-foreground mb-4">
          Add the gateway endpoint and LiveDashboard page to your Phoenix router
        </p>
        <CodeBlock
          code={routerExample}
          language="elixir"
          title="your_app_web/router.ex"
        />
      </div>

      <div>
        <h3 className="text-xl font-semibold mb-3">Dependencies</h3>
        <pre className="p-4 bg-card rounded-lg border border-border overflow-x-auto">
          <code className="text-sm font-mono text-foreground">{`defp deps do
  [
    {:plug, "~> 1.14"},
    {:jason, "~> 1.4"},
    {:telemetry, "~> 1.2"},
    {:phoenix_live_dashboard, "~> 0.8"},
    {:rec_llm, "~> 0.1"}
  ]
end`}</code>
        </pre>
      </div>
    </div>
  )
}
