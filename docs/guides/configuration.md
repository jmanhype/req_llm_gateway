# Configuration Guide

RecLLMGateway offers flexible configuration options for production deployments.

## Core Configuration

All configuration is done via Application environment:

```elixir
# config/config.exs
config :rec_llm_gateway,
  # Provider API keys (required)
  api_keys: %{
    "openai" => System.get_env("OPENAI_API_KEY"),
    "anthropic" => System.get_env("ANTHROPIC_API_KEY")
  },

  # Default provider when no prefix is specified (default: "openai")
  default_provider: "openai",

  # Include x_rec_llm extension in responses (default: true)
  include_extensions: true,

  # Optional gateway authentication
  api_key: System.get_env("GATEWAY_API_KEY")
```

## API Keys

### Provider API Keys

The `api_keys` map defines which LLM providers are available:

```elixir
config :rec_llm_gateway,
  api_keys: %{
    "openai" => "sk-...",
    "anthropic" => "sk-ant-...",
    "custom" => "your-api-key"
  }
```

Use environment variables for security:

```elixir
config :rec_llm_gateway,
  api_keys: %{
    "openai" => System.get_env("OPENAI_API_KEY"),
    "anthropic" => System.get_env("ANTHROPIC_API_KEY")
  }
```

### Gateway Authentication

Optionally require authentication for gateway access:

```elixir
config :rec_llm_gateway,
  api_key: "your-secret-gateway-key"
```

Clients must then provide this key:

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer your-secret-gateway-key" \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4", "messages": [...]}'
```

## Default Provider

When clients don't specify a provider prefix, use this one:

```elixir
config :rec_llm_gateway,
  default_provider: "openai"
```

Now `"model": "gpt-4"` is equivalent to `"model": "openai:gpt-4"`.

## Response Extensions

The `x_rec_llm` extension adds observability data to responses:

```json
{
  "choices": [...],
  "x_rec_llm": {
    "provider": "openai",
    "latency_ms": 342,
    "cost_usd": 0.000063
  }
}
```

Disable if you want pure OpenAI compatibility:

```elixir
config :rec_llm_gateway,
  include_extensions: false
```

## Environment-Specific Configuration

### Development

```elixir
# config/dev.exs
import Config

config :rec_llm_gateway,
  api_keys: %{
    "openai" => System.get_env("OPENAI_API_KEY")
  },
  include_extensions: true
```

### Production

```elixir
# config/runtime.exs
import Config

if config_env() == :prod do
  config :rec_llm_gateway,
    api_keys: %{
      "openai" => System.get_env("OPENAI_API_KEY") || raise("OPENAI_API_KEY not set"),
      "anthropic" => System.get_env("ANTHROPIC_API_KEY") || raise("ANTHROPIC_API_KEY not set")
    },
    api_key: System.get_env("GATEWAY_API_KEY"),
    include_extensions: true
end
```

### Testing

Mock the LLM client to avoid real API calls:

```elixir
# config/test.exs
import Config

config :rec_llm_gateway,
  llm_client: MyApp.LLMClientMock,
  api_keys: %{
    "openai" => "test-key"
  }
```

## Custom LLM Client

For testing or custom provider logic, inject your own client:

```elixir
config :rec_llm_gateway,
  llm_client: MyApp.CustomLLMClient
```

Your client must implement `call/3`:

```elixir
defmodule MyApp.CustomLLMClient do
  def call(provider, request, api_key) do
    # Your custom logic here
    {:ok, %{"choices" => [...], "usage" => %{...}}}
  end
end
```

## Verifying Configuration

Check if your gateway is properly configured:

```elixir
iex> RecLLMGateway.configured?()
{:ok, ["openai", "anthropic"]}

iex> RecLLMGateway.default_provider()
"openai"
```
