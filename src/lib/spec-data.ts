export interface SpecSection {
  id: string
  title: string
  icon: string
}

export interface CodeExample {
  language: string
  code: string
  title?: string
}

export interface Component {
  name: string
  file: string
  description: string
  responsibility: string
}

export interface ModelValidation {
  input: string
  valid: boolean
  provider?: string
  model?: string
  error?: string
}

export const specSections: SpecSection[] = [
  { id: 'overview', title: 'Overview', icon: 'info' },
  { id: 'api', title: 'API Contract', icon: 'code' },
  { id: 'components', title: 'Components', icon: 'package' },
  { id: 'config', title: 'Configuration', icon: 'settings' },
  { id: 'usage', title: 'Usage Examples', icon: 'play' },
  { id: 'testing', title: 'Testing', icon: 'check' },
]

export const components: Component[] = [
  {
    name: 'Plug Handler',
    file: 'rec_llm_gateway/plug.ex',
    description: 'Main endpoint handler for /v1/chat/completions',
    responsibility: 'Receives requests, validates format, routes to providers, adds telemetry, and returns OpenAI-standard responses'
  },
  {
    name: 'Model Parser',
    file: 'rec_llm_gateway/model_parser.ex',
    description: 'Parses provider:model format',
    responsibility: 'Extracts provider and model from request, supports default provider fallback, validates format'
  },
  {
    name: 'Usage Tracker',
    file: 'rec_llm_gateway/usage.ex',
    description: 'ETS-backed usage counters',
    responsibility: 'Records token usage, costs, latency by date/provider/model in-memory with concurrent access'
  },
  {
    name: 'Telemetry',
    file: 'rec_llm_gateway/telemetry.ex',
    description: 'Telemetry event helpers',
    responsibility: 'Emits :start, :stop, :exception events with metrics for observability integrations'
  },
  {
    name: 'Dashboard Page',
    file: 'rec_llm_gateway/dashboard_page.ex',
    description: 'Phoenix LiveDashboard integration',
    responsibility: 'Displays usage statistics table in LiveDashboard with sortable columns and formatted values'
  },
  {
    name: 'Pricing Calculator',
    file: 'rec_llm_gateway/pricing.ex',
    description: 'Optional cost calculation',
    responsibility: 'Calculates USD costs based on token usage and configured model pricing'
  },
]

export const requestExample = `{
  "model": "openai:gpt-4o-mini",
  "messages": [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Hello!"}
  ],
  "temperature": 0.7,
  "max_tokens": 150,
  "stream": false
}`

export const responseExample = `{
  "id": "chatcmpl-abc123",
  "object": "chat.completion",
  "created": 1730342400,
  "model": "gpt-4o-mini",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Hello! How can I help you today?"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 12,
    "completion_tokens": 9,
    "total_tokens": 21
  },
  "x_rec_llm": {
    "provider": "openai",
    "latency_ms": 342,
    "cost_usd": 0.000063
  }
}`

export const configExample = `# config/config.exs
config :rec_llm_gateway,
  default_provider: "openai",
  include_extensions: true

config :rec_llm_gateway, :pricing,
  %{
    "gpt-4o" => %{
      input_per_million: 2.50,
      output_per_million: 10.00
    },
    "gpt-4o-mini" => %{
      input_per_million: 0.15,
      output_per_million: 0.60
    }
  }`

export const routerExample = `# In your_app_web/router.ex

scope "/v1" do
  forward "/chat/completions", RecLLMGateway.Plug
end

live_dashboard "/dashboard",
  metrics: YourAppWeb.Telemetry,
  additional_pages: [
    rec_llm_gateway: RecLLMGateway.DashboardPage
  ]`

export const curlExample = `curl -X POST http://localhost:4000/v1/chat/completions \\
  -H "Content-Type: application/json" \\
  -d '{
    "model": "openai:gpt-4o-mini",
    "messages": [
      {"role": "user", "content": "Hello!"}
    ],
    "temperature": 0.7,
    "max_tokens": 100
  }'`

export const pythonExample = `from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:4000/v1",
    api_key="not-needed"
)

response = client.chat.completions.create(
    model="anthropic:claude-3-sonnet-20240229",
    messages=[
        {"role": "user", "content": "Explain quantum computing"}
    ]
)

print(response.choices[0].message.content)`

export const elixirExample = `Req.post!("http://localhost:4000/v1/chat/completions",
  json: %{
    model: "openai:gpt-4o",
    messages: [
      %{role: "system", content: "You are a helpful assistant"},
      %{role: "user", content: "Write a haiku about Elixir"}
    ],
    temperature: 0.8
  }
)`

export function parseModelFormat(input: string): ModelValidation {
  if (!input || input.trim() === '') {
    return {
      input,
      valid: false,
      error: 'Model name is required'
    }
  }

  const parts = input.split(':')
  
  if (parts.length === 2 && parts[0] && parts[1]) {
    return {
      input,
      valid: true,
      provider: parts[0],
      model: parts[1]
    }
  }
  
  if (parts.length === 1 && parts[0]) {
    return {
      input,
      valid: true,
      provider: 'openai',
      model: parts[0]
    }
  }
  
  return {
    input,
    valid: false,
    error: "Invalid format. Use 'provider:model' or 'model'"
  }
}
