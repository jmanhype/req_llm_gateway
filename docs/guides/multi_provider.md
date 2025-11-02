# Multi-Provider Routing

RecLLMGateway supports routing requests to different LLM providers using a simple `provider:model` syntax.

## Model Format

Specify the provider prefix before the model name:

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

## Supported Providers

### OpenAI

```json
{"model": "openai:gpt-4"}
{"model": "openai:gpt-4-turbo-preview"}
{"model": "openai:gpt-3.5-turbo"}
```

### Anthropic

```json
{"model": "anthropic:claude-3-opus-20240229"}
{"model": "anthropic:claude-3-sonnet-20240229"}
{"model": "anthropic:claude-3-haiku-20240307"}
```

## Default Provider

If you don't specify a provider, the `default_provider` config is used:

```elixir
# config/config.exs
config :rec_llm_gateway,
  default_provider: "openai"
```

Now these are equivalent:

```json
{"model": "gpt-4"}
{"model": "openai:gpt-4"}
```

## Routing Logic

The gateway parses the model string to determine routing:

1. **With prefix**: `"anthropic:claude-3-sonnet-20240229"`
   - Provider: `anthropic`
   - Model: `claude-3-sonnet-20240229`
   - Routes to Anthropic API

2. **Without prefix**: `"gpt-4"`
   - Provider: `default_provider` from config
   - Model: `gpt-4`
   - Routes to configured default

3. **Invalid format**: `"invalid::model"`
   - Returns error: `{:error, "Invalid model format"}`

## Cost Tracking

The gateway automatically calculates costs per provider:

```json
{
  "x_rec_llm": {
    "provider": "openai",
    "cost_usd": 0.000063
  }
}
```

Pricing is configured in `RecLLMGateway.Pricing`.

## Usage Statistics

Usage stats are tracked per provider and model:

```elixir
RecLLMGateway.Usage.get_all()
#=> [
#  %{
#    provider: "openai",
#    model: "gpt-4",
#    calls: 42,
#    cost_usd: 0.128
#  },
#  %{
#    provider: "anthropic",
#    model: "claude-3-sonnet-20240229",
#    calls: 18,
#    cost_usd: 0.054
#  }
#]
```

## Example: A/B Testing Providers

You can easily A/B test different providers:

```elixir
def route_request(user_id) do
  model = if rem(user_id, 2) == 0 do
    "openai:gpt-4"
  else
    "anthropic:claude-3-sonnet-20240229"
  end

  OpenAI.chat([
    model: model,
    messages: [%{role: "user", content: "Hello!"}]
  ])
end
```

## Adding Custom Providers

To add a custom provider:

1. Add API key to config:

```elixir
config :rec_llm_gateway,
  api_keys: %{
    "custom" => System.get_env("CUSTOM_API_KEY")
  }
```

2. Extend `RecLLMGateway.LLMClient` to support your provider's API

3. Add pricing in `RecLLMGateway.Pricing`:

```elixir
defp pricing_for("custom", "my-model") do
  %{
    prompt_tokens: Decimal.new("0.0001"),
    completion_tokens: Decimal.new("0.0002")
  }
end
```

4. Use it:

```json
{"model": "custom:my-model"}
```
