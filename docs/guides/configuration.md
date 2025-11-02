# Configuration Guide

RecLLMGateway offers flexible configuration options for production deployments.

## Core Configuration

RecLLMGateway uses [ReqLLM](https://github.com/agentjido/req_llm) for LLM provider integrations, which supports 45+ providers and 665+ models out of the box.

```elixir
# config/config.exs
config :rec_llm_gateway,
  # Default provider when no prefix is specified (default: "openai")
  default_provider: "openai",

  # Include x_rec_llm extension in responses (default: true)
  include_extensions: true,

  # Optional gateway authentication
  api_key: System.get_env("GATEWAY_API_KEY")

# ReqLLM API key configuration
config :req_llm,
  openai_api_key: System.get_env("OPENAI_API_KEY"),
  anthropic_api_key: System.get_env("ANTHROPIC_API_KEY"),
  google_api_key: System.get_env("GOOGLE_API_KEY")
```

## API Keys

### Provider API Keys

RecLLMGateway uses ReqLLM for provider integrations. API keys are configured through ReqLLM's configuration system, which supports multiple methods:

**Environment Variables (Recommended)**

```bash
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
export GOOGLE_API_KEY="..."
export GROQ_API_KEY="gsk-..."
```

ReqLLM automatically picks up these environment variables.

**Application Config**

```elixir
# config/runtime.exs
config :req_llm,
  openai_api_key: System.get_env("OPENAI_API_KEY"),
  anthropic_api_key: System.get_env("ANTHROPIC_API_KEY"),
  google_api_key: System.get_env("GOOGLE_API_KEY"),
  groq_api_key: System.get_env("GROQ_API_KEY")
```

**Supported Providers**

ReqLLM supports 45+ providers including:
- OpenAI (gpt-4, gpt-4-turbo, gpt-3.5-turbo)
- Anthropic (claude-3-opus, claude-3-sonnet, claude-3-haiku)
- Google (gemini-pro, gemini-1.5-pro)
- Groq (llama3, mixtral)
- OpenRouter, xAI, AWS Bedrock, Cerebras, and many more

See [ReqLLM's provider list](https://github.com/agentjido/req_llm#providers) for the complete catalog.

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
