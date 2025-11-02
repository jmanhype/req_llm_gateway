# RecLLMGateway - Implementation

OpenAI-compatible LLM proxy with telemetry, usage tracking, and multi-provider routing for Elixir/Phoenix applications.

## Features

- **OpenAI-Compatible API** - Works with existing OpenAI SDKs and tools (LangChain, LlamaIndex, etc.)
- **Multi-Provider Routing** - Route to OpenAI, Anthropic, or any LLM provider via `provider:model` syntax
- **Telemetry** - Built-in telemetry events with proper native time units
- **Usage Tracking** - In-memory ETS-based usage tracking per provider/model/date
- **Cost Calculation** - Automatic cost tracking with configurable pricing
- **LiveDashboard Integration** - View usage statistics in Phoenix LiveDashboard
- **CORS Support** - Built-in CORS headers for browser clients
- **Optional Authentication** - Gateway-level API key protection

## Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:rec_llm_gateway, "~> 0.1.0"}
  ]
end
```

## Quick Start

### 1. Configure API Keys

```elixir
# config/config.exs
import Config

config :rec_llm_gateway,
  port: 4000,
  default_provider: "openai",
  api_keys: %{
    "openai" => System.get_env("OPENAI_API_KEY"),
    "anthropic" => System.get_env("ANTHROPIC_API_KEY")
  }
```

### 2. Start the Gateway

The gateway starts automatically as part of your application supervision tree.

```bash
export OPENAI_API_KEY=sk-...
export ANTHROPIC_API_KEY=sk-ant-...
mix run --no-halt
```

### 3. Make Requests

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Model Routing

Models can be specified in two formats:

### Explicit Provider

```json
{
  "model": "openai:gpt-4",
  "messages": [...]
}
```

```json
{
  "model": "anthropic:claude-3-sonnet-20240229",
  "messages": [...]
}
```

### Default Provider

If no provider prefix is given, the `default_provider` from config is used:

```json
{
  "model": "gpt-4",
  "messages": [...]
}
```

## API Specification

### POST /v1/chat/completions

OpenAI-compatible chat completions endpoint.

**Request Body:**

```json
{
  "model": "gpt-4",
  "messages": [
    {"role": "user", "content": "Hello!"}
  ],
  "temperature": 0.7,
  "max_tokens": 150,
  "top_p": 1.0,
  "frequency_penalty": 0,
  "presence_penalty": 0,
  "stop": null
}
```

**Response:**

```json
{
  "id": "chatcmpl-123",
  "object": "chat.completion",
  "created": 1677652288,
  "model": "gpt-4",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "Hello! How can I help you today?"
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 9,
    "completion_tokens": 12,
    "total_tokens": 21
  },
  "x_rec_llm": {
    "provider": "openai",
    "latency_ms": 342,
    "cost_usd": 0.000063
  }
}
```

### Error Responses

Errors follow OpenAI's error format with proper HTTP status codes:

- `400` - Invalid request (validation errors, unsupported features)
- `401` - Authentication error (invalid gateway API key)
- `429` - Rate limit exceeded
- `500` - API error (provider errors)
- `504` - Timeout error

```json
{
  "error": {
    "type": "invalid_request_error",
    "message": "Streaming is not enabled for this gateway.",
    "code": "stream_not_supported"
  }
}
```

## Configuration

### Required Configuration

```elixir
config :rec_llm_gateway,
  api_keys: %{
    "openai" => System.get_env("OPENAI_API_KEY"),
    "anthropic" => System.get_env("ANTHROPIC_API_KEY")
  }
```

### Optional Configuration

```elixir
config :rec_llm_gateway,
  # Server port (default: 4000)
  port: 4000,

  # Default provider when model has no prefix (default: "openai")
  default_provider: "openai",

  # Include x_rec_llm extension in responses (default: true)
  include_extensions: true,

  # Optional gateway-level authentication
  # Set to nil to disable (default: nil)
  api_key: System.get_env("REC_LLM_GATEWAY_KEY"),

  # Custom pricing (optional)
  pricing: %{
    "custom-model" => %{input: 1.0, output: 2.0}
  }
```

## LiveDashboard Integration

Add the gateway page to your LiveDashboard:

```elixir
# lib/my_app_web/router.ex
import Phoenix.LiveDashboard.Router

scope "/" do
  pipe_through :browser

  live_dashboard "/dashboard",
    additional_pages: [
      rec_llm: RecLLMGateway.LiveDashboard
    ]
end
```

Visit `/dashboard/rec_llm` to see usage statistics.

## Telemetry

The gateway emits telemetry events that you can hook into for observability:

### Events

**`[:rec_llm_gateway, :request, :start]`**
- Measurements: `%{system_time: integer}`
- Metadata: `%{provider: string, model: string}`

**`[:rec_llm_gateway, :request, :stop]`**
- Measurements: `%{duration: native_time, prompt_tokens: int, completion_tokens: int, total_tokens: int}`
- Metadata: `%{provider: string, model: string, finish_reason: string}`

**`[:rec_llm_gateway, :request, :exception]`**
- Measurements: `%{}`
- Metadata: `%{error: string}`

### Metrics

```elixir
# lib/my_app/telemetry.ex
def metrics do
  [
    # Counter: Total requests per provider/model
    counter("rec_llm_gateway.request.stop.count",
      tags: [:provider, :model]
    ),

    # Sum: Total tokens used
    sum("rec_llm_gateway.request.stop.total_tokens",
      tags: [:provider, :model]
    ),

    # Distribution: Request latency
    distribution("rec_llm_gateway.request.stop.duration",
      unit: {:native, :millisecond},
      reporter_options: [buckets: [100, 250, 500, 1000, 2500, 5000]],
      tags: [:provider, :model]
    )
  ]
end
```

## Usage Tracking

The gateway automatically tracks usage in ETS. Access programmatically:

```elixir
# Get all usage records
RecLLMGateway.Usage.get_all()
#=> [
#  %{
#    date: ~D[2024-01-15],
#    provider: "openai",
#    model: "gpt-4",
#    calls: 42,
#    prompt_tokens: 1250,
#    completion_tokens: 890,
#    total_tokens: 2140,
#    cost_usd: 0.128,
#    avg_latency_ms: 325
#  }
#]

# Filter by date
RecLLMGateway.Usage.get_by_date(~D[2024-01-15])

# Filter by provider
RecLLMGateway.Usage.get_by_provider("openai")
```

## Testing

The gateway is designed to be testable. Use Mox to mock the LLM client:

```elixir
# test/test_helper.exs
Mox.defmock(RecLLMGateway.LLMClientMock, for: RecLLMGateway.LLMClient)

# test/my_test.exs
defmodule MyTest do
  use ExUnit.Case
  import Mox

  setup :verify_on_exit!

  test "makes LLM request" do
    expect(RecLLMGateway.LLMClientMock, :chat_completion, fn provider, model, request ->
      {:ok, %{
        "choices" => [...],
        "usage" => %{"prompt_tokens" => 10, ...}
      }}
    end)

    # Your test code here
  end
end
```

Run tests:

```bash
mix test
```

## MVP Limitations

The following features are explicitly not supported in the MVP:

- **Streaming** - `stream: true` will return an error. Streaming will be added in a future release.
- **Persistence** - Usage data is stored in ETS and lost on restart. Add a persistence layer if needed.
- **Rate Limiting** - No built-in rate limiting. Use a reverse proxy or add custom middleware.
- **Multi-Node** - Usage tracking is per-node. Use a distributed backend for multi-node deployments.

## Architecture

```
Client (OpenAI SDK)
    │
    ↓
RecLLMGateway.Plug
    │
    ├─→ ModelParser (parse provider:model)
    ├─→ Telemetry (emit events)
    ├─→ LLMClient (call provider API)
    ├─→ Usage (record in ETS)
    └─→ Response (OpenAI shape + x_rec_llm)
```

### Components

- **`RecLLMGateway.Plug`** - HTTP request handler with validation and error mapping
- **`RecLLMGateway.Telemetry`** - Telemetry event emission with native time units
- **`RecLLMGateway.ModelParser`** - Parses `provider:model` format
- **`RecLLMGateway.Usage`** - ETS-based usage tracking
- **`RecLLMGateway.Pricing`** - Cost calculation per model
- **`RecLLMGateway.LLMClient`** - Provider API integration (OpenAI, Anthropic)
- **`RecLLMGateway.LiveDashboard`** - Phoenix LiveDashboard page

## Security

### API Keys

Provider API keys should be stored in environment variables and configured via `config/runtime.exs`:

```elixir
# config/runtime.exs
import Config

if config_env() == :prod do
  config :rec_llm_gateway,
    api_keys: %{
      "openai" => System.fetch_env!("OPENAI_API_KEY"),
      "anthropic" => System.fetch_env!("ANTHROPIC_API_KEY")
    }
end
```

### Gateway Authentication

Enable gateway-level authentication to restrict access:

```elixir
config :rec_llm_gateway,
  api_key: System.get_env("REC_LLM_GATEWAY_KEY")
```

Clients must include the key in the Authorization header:

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer your-gateway-key" \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4", "messages": [...]}'
```

## Deployment

### Standalone

```bash
MIX_ENV=prod mix release
_build/prod/rel/rec_llm_gateway/bin/rec_llm_gateway start
```

### Docker

```dockerfile
FROM elixir:1.14-alpine

WORKDIR /app

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

COPY config config
COPY lib lib

RUN mix compile
RUN mix release

CMD ["_build/prod/rel/rec_llm_gateway/bin/rec_llm_gateway", "start"]
```

### Fly.io

```bash
fly launch
fly secrets set OPENAI_API_KEY=sk-...
fly secrets set ANTHROPIC_API_KEY=sk-ant-...
fly deploy
```

## Troubleshooting

### "Missing API key for provider"

Ensure environment variables are set:

```bash
export OPENAI_API_KEY=sk-...
export ANTHROPIC_API_KEY=sk-ant-...
```

### Usage data is lost on restart

ETS tables are in-memory only. For persistence:
1. Attach a telemetry handler that writes to a database
2. Add a periodic task to export usage data
3. Use the telemetry events to stream to an external system

### Latency is high

Check:
1. Network latency to provider APIs
2. Provider API rate limits
3. Model selection (larger models are slower)

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions welcome! Please open an issue or PR.

## Roadmap

- [ ] Streaming support (SSE)
- [ ] Database persistence for usage
- [ ] Rate limiting and quotas
- [ ] Circuit breakers and retries
- [ ] Advanced routing (latency/cost-based)
- [ ] More provider integrations
- [ ] Request/response transformations
- [ ] PII redaction
