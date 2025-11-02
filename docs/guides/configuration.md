# Configuration Guide

RecLLMGateway uses ReqLLM under the hood, giving you access to 45+ LLM providers with 665+ models out of the box.

## Quick Start

### Environment Variables (Recommended)

ReqLLM automatically picks up API keys from environment variables:

```bash
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
export GOOGLE_API_KEY="..."
export GROQ_API_KEY="gsk_..."
export XAI_API_KEY="xai-..."
# ... and so on
```

That's it! No additional configuration needed.

### Application Config

Alternatively, configure explicitly in your application:

```elixir
# config/config.exs
config :req_llm,
  openai_api_key: System.get_env("OPENAI_API_KEY"),
  anthropic_api_key: System.get_env("ANTHROPIC_API_KEY"),
  google_api_key: System.get_env("GOOGLE_API_KEY"),
  groq_api_key: System.get_env("GROQ_API_KEY")
```

## RecLLMGateway Configuration

```elixir
# config/config.exs
config :rec_llm_gateway,
  # Default provider when no prefix is specified (default: "openai")
  default_provider: "openai",

  # Include x_rec_llm extension in responses (default: true)
  include_extensions: true,

  # Optional gateway authentication
  api_key: System.get_env("GATEWAY_API_KEY")
```

## Supported Providers

RecLLMGateway supports **45+ providers** via ReqLLM:

### Major Providers

| Provider | Models | Environment Variable |
|----------|--------|---------------------|
| **OpenAI** | gpt-4, gpt-3.5-turbo, etc. | `OPENAI_API_KEY` |
| **Anthropic** | claude-3-opus, claude-3-sonnet, claude-3-haiku | `ANTHROPIC_API_KEY` |
| **Google** | gemini-pro, gemini-1.5-pro, gemini-ultra | `GOOGLE_API_KEY` |
| **AWS Bedrock** | Various models via AWS | AWS credentials |
| **Azure OpenAI** | Azure-hosted OpenAI models | `AZURE_OPENAI_API_KEY` |

### Fast Inference Providers

| Provider | Models | Environment Variable |
|----------|--------|---------------------|
| **Groq** | llama3-70b, llama3-8b, mixtral-8x7b | `GROQ_API_KEY` |
| **Cerebras** | llama3.1-8b, llama3.1-70b | `CEREBRAS_API_KEY` |
| **Together AI** | Various open models | `TOGETHER_API_KEY` |
| **Fireworks AI** | Various open models | `FIREWORKS_API_KEY` |

### Emerging Providers

| Provider | Models | Environment Variable |
|----------|--------|---------------------|
| **xAI** | grok-beta | `XAI_API_KEY` |
| **Mistral AI** | mistral-large, mistral-medium | `MISTRAL_API_KEY` |
| **Cohere** | command, command-light | `COHERE_API_KEY` |
| **AI21** | jurassic-2 | `AI21_API_KEY` |

### Aggregators

| Provider | Description | Environment Variable |
|----------|-------------|---------------------|
| **OpenRouter** | Unified access to 100+ models | `OPENROUTER_API_KEY` |
| **Anyscale** | Serverless endpoints | `ANYSCALE_API_KEY` |

### Open Source & Local

| Provider | Description | Configuration |
|----------|-------------|--------------|
| **Ollama** | Local model hosting | Base URL config |
| **LM Studio** | Local model hosting | Base URL config |
| **vLLM** | Self-hosted inference | Base URL config |

**And 25+ more!** See [ReqLLM documentation](https://hexdocs.pm/req_llm) for the complete list.

## Usage Examples

### Using Different Providers

```elixir
# OpenAI
curl http://localhost:4000/v1/chat/completions \
  -d '{"model": "openai:gpt-4", "messages": [...]}'

# Anthropic
curl http://localhost:4000/v1/chat/completions \
  -d '{"model": "anthropic:claude-3-opus-20240229", "messages": [...]}'

# Google
curl http://localhost:4000/v1/chat/completions \
  -d '{"model": "google:gemini-1.5-pro", "messages": [...]}'

# Groq (fast inference)
curl http://localhost:4000/v1/chat/completions \
  -d '{"model": "groq:llama3-70b-8192", "messages": [...]}'

# xAI
curl http://localhost:4000/v1/chat/completions \
  -d '{"model": "xai:grok-beta", "messages": [...]}'
```

### Default Provider

Set a default provider for models without a prefix:

```elixir
config :rec_llm_gateway,
  default_provider: "openai"
```

Now `"model": "gpt-4"` automatically becomes `"model": "openai:gpt-4"`.

## Gateway Authentication

Optionally require authentication for gateway access:

```elixir
config :rec_llm_gateway,
  api_key: "your-secret-gateway-key"
```

Clients must provide this key:

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer your-secret-gateway-key" \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4", "messages": [...]}'
```

## Response Extensions

The `x_rec_llm` extension adds observability data:

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

Disable for pure OpenAI compatibility:

```elixir
config :rec_llm_gateway,
  include_extensions: false
```

## Environment-Specific Configuration

### Development

```elixir
# config/dev.exs
import Config

config :req_llm,
  openai_api_key: System.get_env("OPENAI_API_KEY"),
  anthropic_api_key: System.get_env("ANTHROPIC_API_KEY")

config :rec_llm_gateway,
  default_provider: "openai",
  include_extensions: true
```

### Production

```elixir
# config/runtime.exs
import Config

if config_env() == :prod do
  config :req_llm,
    openai_api_key: System.get_env("OPENAI_API_KEY") || raise("OPENAI_API_KEY not set"),
    anthropic_api_key: System.get_env("ANTHROPIC_API_KEY") || raise("ANTHROPIC_API_KEY not set"),
    google_api_key: System.get_env("GOOGLE_API_KEY")

  config :rec_llm_gateway,
    api_key: System.get_env("GATEWAY_API_KEY"),
    default_provider: "openai",
    include_extensions: true
end
```

### Testing

Mock the LLM client to avoid real API calls:

```elixir
# config/test.exs
import Config

config :rec_llm_gateway,
  llm_client: MyApp.LLMClientMock
```

## ReqLLM Features

RecLLMGateway inherits these features from ReqLLM:

### Automatic Cost Calculation

ReqLLM knows pricing for 665+ models:

```elixir
# Costs are automatically calculated and included in responses
{:ok, response} = RecLLMGateway.LLMClient.chat_completion("openai", "gpt-4", request)
# response["x_rec_llm"]["cost_usd"] => 0.000063
```

### Token Counting

Usage tracking works automatically:

```elixir
# response["usage"]
%{
  "prompt_tokens" => 10,
  "completion_tokens" => 20,
  "total_tokens" => 30
}
```

### Model Registry

Access model metadata:

```elixir
# ReqLLM maintains a registry of 665+ models with:
# - Pricing information
# - Context window sizes
# - Capabilities (vision, function calling, etc.)
# - Provider-specific configuration
```

### HTTP/2 Streaming

ReqLLM supports streaming for compatible providers:

```elixir
# (Coming soon in RecLLMGateway)
{"model": "openai:gpt-4", "stream": true}
```

## Provider-Specific Configuration

### AWS Bedrock

```bash
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_REGION="us-east-1"
```

### Azure OpenAI

```elixir
config :req_llm,
  azure_openai_api_key: System.get_env("AZURE_OPENAI_API_KEY"),
  azure_openai_endpoint: "https://your-resource.openai.azure.com"
```

### Ollama (Local)

```elixir
config :req_llm,
  ollama_base_url: "http://localhost:11434"
```

### Custom Base URLs

For self-hosted or proxy endpoints:

```elixir
config :req_llm,
  openai_base_url: "https://your-proxy.com/v1"
```

## Migration from Old Configuration

If you're upgrading from a version that used custom `api_keys`:

**Before:**
```elixir
config :rec_llm_gateway,
  api_keys: %{
    "openai" => System.get_env("OPENAI_API_KEY"),
    "anthropic" => System.get_env("ANTHROPIC_API_KEY")
  }
```

**After:**
```elixir
# Just set environment variables!
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."

# Or use ReqLLM config
config :req_llm,
  openai_api_key: System.get_env("OPENAI_API_KEY"),
  anthropic_api_key: System.get_env("ANTHROPIC_API_KEY")
```

## Troubleshooting

### Missing API Key

```
** (RuntimeError) Missing API key for provider: openai
```

**Solution:** Set the environment variable or config:

```bash
export OPENAI_API_KEY="sk-..."
```

### Unsupported Provider

```
{:error, %{type: "api_error", message: "Unsupported provider: custom"}}
```

**Solution:** Check the [ReqLLM documentation](https://hexdocs.pm/req_llm) for supported providers.

### Authentication Errors

```
{:error, %{type: "auth_error", message: "Invalid API key"}}
```

**Solution:** Verify your API key is correct and has proper permissions.

## Next Steps

- [Getting Started Guide](getting_started.md) - Full setup walkthrough
- [ReqLLM Documentation](https://hexdocs.pm/req_llm) - Complete provider list and features
- [Model Registry](https://hexdocs.pm/req_llm/model-registry.html) - Browse 665+ supported models
