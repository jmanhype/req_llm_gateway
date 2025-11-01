import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { CheckCircle } from '@phosphor-icons/react'

export function TestingSection() {
  return (
    <div className="flex flex-col gap-6">
      <div>
        <h2 className="text-3xl font-bold mb-3">Testing Strategy</h2>
        <p className="text-lg text-muted-foreground">
          Comprehensive test coverage for gateway functionality
        </p>
      </div>

      <div>
        <h3 className="text-xl font-semibold mb-3">Test Modules</h3>
        <div className="grid gap-3">
          <Card className="p-4">
            <div className="flex flex-col gap-3">
              <div className="flex items-start justify-between">
                <code className="font-mono text-sm font-semibold">plug_test.exs</code>
                <Badge variant="secondary">Core</Badge>
              </div>
              <p className="text-sm text-muted-foreground">
                Tests for the main Plug handler including request validation, provider routing, 
                response formatting, and error handling
              </p>
            </div>
          </Card>

          <Card className="p-4">
            <div className="flex flex-col gap-3">
              <div className="flex items-start justify-between">
                <code className="font-mono text-sm font-semibold">model_parser_test.exs</code>
                <Badge variant="secondary">Parser</Badge>
              </div>
              <p className="text-sm text-muted-foreground">
                Tests for model format parsing including provider:model syntax, 
                default provider fallback, and error cases
              </p>
            </div>
          </Card>

          <Card className="p-4">
            <div className="flex flex-col gap-3">
              <div className="flex items-start justify-between">
                <code className="font-mono text-sm font-semibold">usage_test.exs</code>
                <Badge variant="secondary">Storage</Badge>
              </div>
              <p className="text-sm text-muted-foreground">
                Tests for ETS-backed usage tracking including recording metrics, 
                retrieving by date, and concurrent access
              </p>
            </div>
          </Card>
        </div>
      </div>

      <div>
        <h3 className="text-xl font-semibold mb-3">Test Coverage Areas</h3>
        <div className="grid gap-2">
          {[
            'Valid OpenAI format requests return 200',
            'Missing required fields return 400 with error',
            'Provider:model format parsing works correctly',
            'Default provider fallback applies when no prefix',
            'x_rec_llm extensions included when configured',
            'Usage metrics recorded to ETS',
            'Telemetry events emitted correctly',
            'OpenAI-standard error format returned',
            'Invalid model formats return descriptive errors',
            'Concurrent usage tracking works without race conditions',
          ].map((test) => (
            <Card key={test} className="p-3">
              <div className="flex items-start gap-2">
                <CheckCircle className="text-teal mt-0.5 flex-shrink-0" weight="fill" size={16} />
                <span className="text-sm text-foreground">{test}</span>
              </div>
            </Card>
          ))}
        </div>
      </div>

      <div>
        <h3 className="text-xl font-semibold mb-3">Running Tests</h3>
        <pre className="p-4 bg-card rounded-lg border border-border overflow-x-auto">
          <code className="text-sm font-mono text-foreground">{`# Run all tests
mix test

# Run specific test file
mix test test/rec_llm_gateway/plug_test.exs

# Run with coverage
mix test --cover

# Run in watch mode
mix test.watch`}</code>
        </pre>
      </div>

      <div>
        <h3 className="text-xl font-semibold mb-3">Mocking Strategy</h3>
        <Card className="p-4 bg-muted/30">
          <p className="text-sm text-foreground leading-relaxed">
            Tests mock <code className="px-1.5 py-0.5 bg-background rounded font-mono">RecLLM.chat_completion/3</code> calls 
            to avoid hitting real provider APIs. Use Mox or similar mocking libraries to stub provider responses 
            and test error scenarios without external dependencies.
          </p>
        </Card>
      </div>
    </div>
  )
}
