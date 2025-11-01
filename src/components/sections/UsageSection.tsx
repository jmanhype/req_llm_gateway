import React from 'react'
import { CodeBlock } from '@/components/CodeBlock'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { curlExample, pythonExample, elixirExample } from '@/lib/spec-data'
import { Card } from '@/components/ui/card'

export function UsageSection() {
  return (
    <div className="flex flex-col gap-6">
      <div>
        <h2 className="text-3xl font-bold mb-3">Usage Examples</h2>
        <p className="text-lg text-muted-foreground">
          How to use the gateway from different clients and languages
        </p>
      </div>

      <Card className="p-6 bg-gradient-to-br from-primary/5 to-transparent">
        <h3 className="text-lg font-semibold mb-2">OpenAI SDK Compatibility</h3>
        <p className="text-muted-foreground leading-relaxed">
          Because RecLLMGateway implements the OpenAI Chat Completions API, you can use any OpenAI-compatible 
          SDK by simply changing the <code className="px-1.5 py-0.5 bg-muted rounded text-sm font-mono">base_url</code> to 
          point to your gateway endpoint. This works with official SDKs for Python, JavaScript, Go, and more.
        </p>
      </Card>

      <Tabs defaultValue="curl" className="w-full">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="curl">cURL</TabsTrigger>
          <TabsTrigger value="python">Python</TabsTrigger>
          <TabsTrigger value="elixir">Elixir</TabsTrigger>
        </TabsList>

        <TabsContent value="curl" className="mt-4">
          <CodeBlock
            code={curlExample}
            language="bash"
            title="Basic cURL Request"
          />
          <p className="text-sm text-muted-foreground mt-3">
            Direct HTTP POST request to the gateway endpoint
          </p>
        </TabsContent>

        <TabsContent value="python" className="mt-4">
          <CodeBlock
            code={pythonExample}
            language="python"
            title="Using OpenAI Python SDK"
          />
          <p className="text-sm text-muted-foreground mt-3">
            Point the OpenAI SDK to your gateway by setting <code className="px-1.5 py-0.5 bg-muted rounded text-xs font-mono">base_url</code>. 
            The model parameter uses the <code className="px-1.5 py-0.5 bg-muted rounded text-xs font-mono">provider:model</code> format.
          </p>
        </TabsContent>

        <TabsContent value="elixir" className="mt-4">
          <CodeBlock
            code={elixirExample}
            language="elixir"
            title="Using Req HTTP Client"
          />
          <p className="text-sm text-muted-foreground mt-3">
            Make HTTP requests from Elixir applications using Req or HTTPoison
          </p>
        </TabsContent>
      </Tabs>

      <div>
        <h3 className="text-xl font-semibold mb-3">Common Use Cases</h3>
        <div className="grid gap-3">
          <Card className="p-4">
            <h4 className="font-semibold mb-2">Multi-Provider Fallback</h4>
            <p className="text-sm text-muted-foreground">
              Try OpenAI first, fall back to Anthropic if rate limited
            </p>
          </Card>
          <Card className="p-4">
            <h4 className="font-semibold mb-2">Cost Optimization</h4>
            <p className="text-sm text-muted-foreground">
              Route simple queries to gpt-4o-mini, complex ones to gpt-4o
            </p>
          </Card>
          <Card className="p-4">
            <h4 className="font-semibold mb-2">A/B Testing</h4>
            <p className="text-sm text-muted-foreground">
              Compare model performance by splitting traffic between providers
            </p>
          </Card>
          <Card className="p-4">
            <h4 className="font-semibold mb-2">Centralized Monitoring</h4>
            <p className="text-sm text-muted-foreground">
              Track all LLM usage across your application in one place
            </p>
          </Card>
        </div>
      </div>
    </div>
  )
}
