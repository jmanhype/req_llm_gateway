# Telemetry & Monitoring

ReqLLMGateway emits comprehensive telemetry events for observability and monitoring.

## Telemetry Events

### `[:req_llm_gateway, :request, :start]`

Emitted when a request begins.

**Measurements**: `%{system_time: integer()}`

**Metadata**:
```elixir
%{
  provider: "openai",
  model: "gpt-4",
  request_id: "unique-id"
}
```

### `[:req_llm_gateway, :request, :stop]`

Emitted when a request completes successfully.

**Measurements**:
```elixir
%{
  duration: 342_000_000,  # nanoseconds
  prompt_tokens: 10,
  completion_tokens: 20,
  total_tokens: 30,
  cost_usd: Decimal.new("0.000063")
}
```

**Metadata**:
```elixir
%{
  provider: "openai",
  model: "gpt-4",
  request_id: "unique-id"
}
```

### `[:req_llm_gateway, :request, :exception]`

Emitted when a request fails.

**Measurements**: `%{duration: integer()}`

**Metadata**:
```elixir
%{
  provider: "openai",
  model: "gpt-4",
  request_id: "unique-id",
  kind: :error,
  reason: %RuntimeError{},
  stacktrace: [...]
}
```

## Attaching Handlers

### Basic Handler

```elixir
:telemetry.attach(
  "my-handler",
  [:req_llm_gateway, :request, :stop],
  fn event, measurements, metadata, _config ->
    IO.inspect({event, measurements, metadata})
  end,
  nil
)
```

### Logger Integration

```elixir
defmodule MyApp.Telemetry do
  require Logger

  def setup do
    :telemetry.attach_many(
      "my-app-req-llm-handler",
      [
        [:req_llm_gateway, :request, :start],
        [:req_llm_gateway, :request, :stop],
        [:req_llm_gateway, :request, :exception]
      ],
      &handle_event/4,
      nil
    )
  end

  def handle_event([:req_llm_gateway, :request, :start], _measurements, metadata, _config) do
    Logger.info("LLM request started: #{metadata.provider}:#{metadata.model}")
  end

  def handle_event([:req_llm_gateway, :request, :stop], measurements, metadata, _config) do
    duration_ms = measurements.duration / 1_000_000

    Logger.info(
      "LLM request completed: #{metadata.provider}:#{metadata.model} " <>
      "duration=#{duration_ms}ms tokens=#{measurements.total_tokens} " <>
      "cost=$#{measurements.cost_usd}"
    )
  end

  def handle_event([:req_llm_gateway, :request, :exception], _measurements, metadata, _config) do
    Logger.error("LLM request failed: #{metadata.provider}:#{metadata.model} " <>
                 "reason=#{inspect(metadata.reason)}")
  end
end
```

Then in your `Application.start/2`:

```elixir
defmodule MyApp.Application do
  def start(_type, _args) do
    MyApp.Telemetry.setup()
    # ...
  end
end
```

## Prometheus Metrics

Integrate with Prometheus using `TelemetryMetrics` and `TelemetryMetricsPrometheus`:

```elixir
# mix.exs
{:telemetry_metrics_prometheus, "~> 1.1"}
```

```elixir
defmodule MyApp.PrometheusTelemetry do
  use Supervisor
  alias Telemetry.Metrics

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    children = [
      {TelemetryMetricsPrometheus, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp metrics do
    [
      # Request count
      Metrics.counter("req_llm_gateway.request.count",
        tags: [:provider, :model]
      ),

      # Request duration
      Metrics.distribution("req_llm_gateway.request.duration",
        unit: {:native, :millisecond},
        tags: [:provider, :model],
        reporter_options: [buckets: [10, 100, 500, 1000, 5000]]
      ),

      # Token usage
      Metrics.sum("req_llm_gateway.request.tokens",
        measurement: :total_tokens,
        tags: [:provider, :model]
      ),

      # Cost tracking
      Metrics.sum("req_llm_gateway.request.cost",
        measurement: :cost_usd,
        tags: [:provider, :model]
      ),

      # Error count
      Metrics.counter("req_llm_gateway.request.exception.count",
        tags: [:provider, :model]
      )
    ]
  end
end
```

## StatsD Integration

```elixir
# mix.exs
{:statix, "~> 1.4"}
```

```elixir
defmodule MyApp.StatsDTelemetry do
  use Statix

  def setup do
    :telemetry.attach(
      "my-app-statsd",
      [:req_llm_gateway, :request, :stop],
      &handle_event/4,
      nil
    )
  end

  def handle_event(_event, measurements, metadata, _config) do
    duration_ms = measurements.duration / 1_000_000
    tags = ["provider:#{metadata.provider}", "model:#{metadata.model}"]

    timing("llm.request.duration", duration_ms, tags: tags)
    increment("llm.request.count", 1, tags: tags)
    gauge("llm.request.tokens", measurements.total_tokens, tags: tags)
  end
end
```

## Custom Metrics Dashboard

Create a GenServer to aggregate metrics:

```elixir
defmodule MyApp.LLMMetrics do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    :telemetry.attach(
      "llm-metrics",
      [:req_llm_gateway, :request, :stop],
      &handle_telemetry/4,
      nil
    )

    {:ok, %{requests: 0, total_cost: Decimal.new(0), total_tokens: 0}}
  end

  def handle_telemetry(_event, measurements, _metadata, _config) do
    GenServer.cast(__MODULE__, {:track, measurements})
  end

  def handle_cast({:track, measurements}, state) do
    new_state = %{
      state |
      requests: state.requests + 1,
      total_cost: Decimal.add(state.total_cost, measurements.cost_usd),
      total_tokens: state.total_tokens + measurements.total_tokens
    }

    {:noreply, new_state}
  end

  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  def handle_call(:get_stats, _from, state) do
    {:reply, state, state}
  end
end
```

## LiveDashboard Integration

ReqLLMGateway includes a built-in LiveDashboard page:

```elixir
# router.ex
live_dashboard "/dashboard",
  additional_pages: [
    req_llm: ReqLLMGateway.LiveDashboard
  ]
```

View at `http://localhost:4000/dashboard/req_llm`.
