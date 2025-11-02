# Standalone Gateway Example

Run RecLLMGateway as a standalone HTTP service without Phoenix.

## Setup

Create `mix.exs`:

```elixir
defmodule LLMGateway.MixProject do
  use Mix.Project

  def project do
    [
      app: :llm_gateway,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {LLMGateway.Application, []}
    ]
  end

  defp deps do
    [
      {:rec_llm_gateway, "~> 0.1.0"},
      {:plug_cowboy, "~> 2.6"}
    ]
  end
end
```

## Application Module

Create `lib/llm_gateway/application.ex`:

```elixir
defmodule LLMGateway.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Plug.Cowboy,
       scheme: :http,
       plug: LLMGateway.Router,
       options: [port: 4000]}
    ]

    opts = [strategy: :one_for_one, name: LLMGateway.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## Router

Create `lib/llm_gateway/router.ex`:

```elixir
defmodule LLMGateway.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  forward "/v1/chat/completions", to: RecLLMGateway.Plug

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
```

## Configuration

Create `config/config.exs`:

```elixir
import Config

config :rec_llm_gateway,
  api_keys: %{
    "openai" => System.get_env("OPENAI_API_KEY"),
    "anthropic" => System.get_env("ANTHROPIC_API_KEY")
  }
```

## Run

```bash
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."

mix deps.get
mix run --no-halt
```

Gateway is now available at `http://localhost:4000/v1/chat/completions`.

## Docker

Create `Dockerfile`:

```dockerfile
FROM elixir:1.16-alpine AS build

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

COPY config ./config
COPY lib ./lib

RUN mix compile

FROM elixir:1.16-alpine

WORKDIR /app

COPY --from=build /app/_build /app/_build
COPY --from=build /app/deps /app/deps
COPY config ./config
COPY lib ./lib
COPY mix.exs mix.lock ./

ENV MIX_ENV=prod

CMD ["mix", "run", "--no-halt"]
```

Build and run:

```bash
docker build -t llm-gateway .
docker run -p 4000:4000 \
  -e OPENAI_API_KEY="sk-..." \
  -e ANTHROPIC_API_KEY="sk-ant-..." \
  llm-gateway
```

## Kubernetes Deployment

Create `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: llm-gateway
spec:
  replicas: 3
  selector:
    matchLabels:
      app: llm-gateway
  template:
    metadata:
      labels:
        app: llm-gateway
    spec:
      containers:
      - name: llm-gateway
        image: llm-gateway:latest
        ports:
        - containerPort: 4000
        env:
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:
              name: llm-secrets
              key: openai-key
        - name: ANTHROPIC_API_KEY
          valueFrom:
            secretKeyRef:
              name: llm-secrets
              key: anthropic-key
---
apiVersion: v1
kind: Service
metadata:
  name: llm-gateway
spec:
  selector:
    app: llm-gateway
  ports:
  - port: 80
    targetPort: 4000
  type: LoadBalancer
```

Deploy:

```bash
kubectl apply -f deployment.yaml
```
