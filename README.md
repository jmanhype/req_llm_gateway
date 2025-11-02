# RecLLMGateway

**OpenAI-compatible LLM proxy. Drop into Phoenix. Done.**

```elixir
# In your router.ex
forward "/v1/chat/completions", RecLLMGateway.Plug
```

That's it. You now have a production-ready LLM gateway.

## What You Get

- ✅ **OpenAI-compatible endpoint** - Works with existing SDKs (Python, JS, curl)
- ✅ **45+ LLM providers** - Powered by [ReqLLM](https://github.com/agentjido/req_llm) with 665+ models
- ✅ **Multi-provider routing** - `openai:gpt-4`, `anthropic:claude-3-sonnet`, `google:gemini-pro`
- ✅ **Built-in telemetry** - Emit events for observability
- ✅ **Usage tracking** - ETS-backed stats (no database needed)
- ✅ **Automatic cost tracking** - ReqLLM calculates costs per provider/model
- ✅ **LiveDashboard** - See usage stats at `/dashboard/rec_llm`

## Installation

Add to `mix.exs`:

```elixir
def deps do
  [
    {:rec_llm_gateway, "~> 0.1.0"}
  ]
end
```

## Quick Start

### 1. Configure API Keys

RecLLMGateway uses [ReqLLM](https://github.com/agentjido/req_llm) for provider integrations. Configure via environment variables:

```bash
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
```

Or in config:

```elixir
# config/config.exs
config :req_llm,
  openai_api_key: System.get_env("OPENAI_API_KEY"),
  anthropic_api_key: System.get_env("ANTHROPIC_API_KEY")
```

### 2. Add to Router

```elixir
# lib/my_app_web/router.ex
scope "/v1" do
  forward "/chat/completions", RecLLMGateway.Plug
end

# Add LiveDashboard page
live_dashboard "/dashboard",
  additional_pages: [
    rec_llm: RecLLMGateway.LiveDashboard
  ]
```

### 3. Use It

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai:gpt-4",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Model Routing

Specify provider explicitly:
```json
{"model": "openai:gpt-4"}
{"model": "anthropic:claude-3-sonnet-20240229"}
```

Or use default provider:
```json
{"model": "gpt-4"}  // Uses default_provider from config
```

## Response Format

Standard OpenAI response + optional extensions:

```json
{
  "choices": [...],
  "usage": {"prompt_tokens": 10, "completion_tokens": 20},
  "x_rec_llm": {
    "provider": "openai",
    "latency_ms": 342,
    "cost_usd": 0.000063
  }
}
```

## Works With Existing Tools

**Python:**
```python
from openai import OpenAI

client = OpenAI(base_url="http://localhost:4000/v1", api_key="not-needed")
response = client.chat.completions.create(
    model="anthropic:claude-3-sonnet-20240229",
    messages=[{"role": "user", "content": "Hello!"}]
)
```

**JavaScript, Go, Ruby** - Any OpenAI-compatible SDK works.

## Configuration Options

```elixir
config :rec_llm_gateway,
  # Default provider when model has no prefix (default: "openai")
  default_provider: "openai",

  # Include x_rec_llm extension in responses (default: true)
  include_extensions: true,

  # Optional gateway authentication
  api_key: System.get_env("GATEWAY_API_KEY"),

  # Provider API keys
  api_keys: %{
    "openai" => System.get_env("OPENAI_API_KEY"),
    "anthropic" => System.get_env("ANTHROPIC_API_KEY")
  }
```

## Usage Tracking

Stats are automatically tracked in ETS:

```elixir
RecLLMGateway.Usage.get_all()
#=> [
#  %{
#    date: ~D[2024-01-15],
#    provider: "openai",
#    model: "gpt-4",
#    calls: 42,
#    total_tokens: 2140,
#    cost_usd: 0.128,
#    avg_latency_ms: 325
#  }
#]
```

Or view in LiveDashboard at `/dashboard/rec_llm`.

## Telemetry

Emits standard telemetry events:

- `[:rec_llm_gateway, :request, :start]`
- `[:rec_llm_gateway, :request, :stop]` - includes tokens, latency
- `[:rec_llm_gateway, :request, :exception]`

Hook into your existing observability stack.

## Testing

Mock the LLM client in tests:

```elixir
# config/test.exs
config :rec_llm_gateway,
  llm_client: MyApp.LLMClientMock
```

See `test/` directory for examples.

## That's It

~500 lines of code. Zero JavaScript. No database. Just Elixir.

Add it to your Phoenix app and you have a production-ready LLM gateway with telemetry, usage tracking, and multi-provider routing.

**Heads will explode.** 🤯

## MVP Limitations

- **No streaming** - `stream: true` returns an error (coming soon)
- **No persistence** - Usage data is in-memory (restart = reset)
- **No rate limiting** - Add a reverse proxy if needed

## License

MIT
