# Getting Started

This guide will help you get RecLLMGateway up and running in your Elixir/Phoenix application.

## Prerequisites

- Elixir 1.14 or later
- Phoenix 1.7+ (optional, but recommended)
- API keys for at least one LLM provider (OpenAI, Anthropic, etc.)

## Installation

Add RecLLMGateway to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:rec_llm_gateway, "~> 0.1.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Configuration

Configure your LLM provider API keys in `config/config.exs`:

```elixir
config :rec_llm_gateway,
  api_keys: %{
    "openai" => System.get_env("OPENAI_API_KEY"),
    "anthropic" => System.get_env("ANTHROPIC_API_KEY")
  },
  default_provider: "openai",
  include_extensions: true
```

### Environment Variables

Create a `.env` file (or use your deployment environment):

```bash
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
```

## Adding to Your Phoenix Router

In your Phoenix router (`lib/my_app_web/router.ex`), add:

```elixir
scope "/v1" do
  forward "/chat/completions", RecLLMGateway.Plug
end
```

That's it! Your gateway is now live at `http://localhost:4000/v1/chat/completions`.

## Optional: LiveDashboard Integration

To monitor usage stats in real-time, add the LiveDashboard page:

```elixir
# In your router
import Phoenix.LiveDashboard.Router

scope "/" do
  pipe_through :browser

  live_dashboard "/dashboard",
    metrics: MyAppWeb.Telemetry,
    additional_pages: [
      rec_llm: RecLLMGateway.LiveDashboard
    ]
end
```

View stats at `http://localhost:4000/dashboard/rec_llm`.

## Testing Your Setup

### Using curl

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai:gpt-4",
    "messages": [{"role": "user", "content": "Hello, world!"}]
  }'
```

### Using the OpenAI Python SDK

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:4000/v1",
    api_key="not-needed"  # Gateway doesn't require auth by default
)

response = client.chat.completions.create(
    model="openai:gpt-4",
    messages=[{"role": "user", "content": "Hello!"}]
)

print(response.choices[0].message.content)
```

### Using the OpenAI Node.js SDK

```javascript
import OpenAI from 'openai';

const client = new OpenAI({
  baseURL: 'http://localhost:4000/v1',
  apiKey: 'not-needed',
});

const response = await client.chat.completions.create({
  model: 'anthropic:claude-3-sonnet-20240229',
  messages: [{ role: 'user', content: 'Hello!' }],
});

console.log(response.choices[0].message.content);
```

## Next Steps

- Read the [Configuration Guide](configuration.md) for advanced options
- Learn about [Multi-Provider Routing](multi_provider.md)
- Set up [Telemetry & Monitoring](telemetry.md)
- Review [Testing Strategies](testing.md)
