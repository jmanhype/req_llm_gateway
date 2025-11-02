# Basic Phoenix App Example

This example shows how to integrate RecLLMGateway into a new Phoenix application.

## Setup

1. Create a new Phoenix app:

```bash
mix phx.new my_app --no-ecto
cd my_app
```

2. Add RecLLMGateway to `mix.exs`:

```elixir
defp deps do
  [
    {:phoenix, "~> 1.7.0"},
    {:rec_llm_gateway, "~> 0.1.0"}  # Add this
  ]
end
```

3. Install dependencies:

```bash
mix deps.get
```

## Configuration

Add to `config/config.exs`:

```elixir
config :rec_llm_gateway,
  api_keys: %{
    "openai" => System.get_env("OPENAI_API_KEY"),
    "anthropic" => System.get_env("ANTHROPIC_API_KEY")
  },
  default_provider: "openai",
  include_extensions: true
```

Create `.env` file:

```bash
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
```

## Router Integration

In `lib/my_app_web/router.ex`:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/v1", MyAppWeb do
    pipe_through :api
    forward "/chat/completions", RecLLMGateway.Plug
  end

  # Optional: Add LiveDashboard
  import Phoenix.LiveDashboard.Router

  scope "/" do
    pipe_through :browser

    live_dashboard "/dashboard",
      metrics: MyAppWeb.Telemetry,
      additional_pages: [
        rec_llm: RecLLMGateway.LiveDashboard
      ]
  end
end
```

## Test It

Start the server:

```bash
source .env
mix phx.server
```

Make a request:

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai:gpt-4",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

View stats at: `http://localhost:4000/dashboard/rec_llm`

## Next Steps

- Add authentication middleware
- Configure custom telemetry handlers
- Set up monitoring with Prometheus
- Deploy to production
