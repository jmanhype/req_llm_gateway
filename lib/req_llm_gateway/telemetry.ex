defmodule ReqLLMGateway.Telemetry do
  @moduledoc """
  Telemetry event emission and metrics definitions.

  ## Events

  - `[:req_llm_gateway, :request, :start]` - Emitted when a request starts
    - Measurements: `%{system_time: integer}`
    - Metadata: `%{provider: string, model: string}`

  - `[:req_llm_gateway, :request, :stop]` - Emitted when a request completes
    - Measurements: `%{duration: native_time, prompt_tokens: integer, completion_tokens: integer, total_tokens: integer}`
    - Metadata: `%{provider: string, model: string, finish_reason: string}`

  - `[:req_llm_gateway, :request, :exception]` - Emitted when a request fails
    - Measurements: `%{}`
    - Metadata: `%{error: string}`
  """

  def emit_start(provider, model) do
    :telemetry.execute(
      [:req_llm_gateway, :request, :start],
      %{system_time: System.system_time()},
      %{provider: provider, model: model}
    )
  end

  @doc """
  Emits a stop event with native time duration.

  The duration is emitted in :native time units and converted to milliseconds
  by the metrics reporters using the unit: {:native, :millisecond} option.
  """
  def emit_stop(request, response, provider, duration_native) do
    usage = Map.get(response, "usage", %{})

    :telemetry.execute(
      [:req_llm_gateway, :request, :stop],
      %{
        duration: duration_native,
        prompt_tokens: Map.get(usage, "prompt_tokens", 0),
        completion_tokens: Map.get(usage, "completion_tokens", 0),
        total_tokens: Map.get(usage, "total_tokens", 0)
      },
      %{
        provider: provider,
        model: response["model"],
        finish_reason: get_finish_reason(response)
      }
    )
  end

  def emit_exception(error) do
    :telemetry.execute(
      [:req_llm_gateway, :request, :exception],
      %{},
      %{error: inspect(error)}
    )
  end

  @doc """
  Returns the list of metrics for telemetry reporters.

  These metrics are designed to work with TelemetryMetrics reporters like
  TelemetryMetrics.ConsoleReporter or Prometheus.
  """
  def metrics do
    [
      # Request counters
      Telemetry.Metrics.counter("req_llm_gateway.request.stop.count",
        tags: [:provider, :model]
      ),
      Telemetry.Metrics.counter("req_llm_gateway.request.exception.count",
        tags: [:error]
      ),

      # Token sums
      Telemetry.Metrics.sum("req_llm_gateway.request.stop.prompt_tokens",
        tags: [:provider, :model]
      ),
      Telemetry.Metrics.sum("req_llm_gateway.request.stop.completion_tokens",
        tags: [:provider, :model]
      ),
      Telemetry.Metrics.sum("req_llm_gateway.request.stop.total_tokens",
        tags: [:provider, :model]
      ),

      # Latency metrics (native -> millisecond conversion)
      Telemetry.Metrics.summary("req_llm_gateway.request.stop.duration",
        unit: {:native, :millisecond},
        tags: [:provider, :model]
      ),
      Telemetry.Metrics.distribution("req_llm_gateway.request.stop.duration",
        unit: {:native, :millisecond},
        reporter_options: [buckets: [100, 250, 500, 1000, 2500, 5000]],
        tags: [:provider, :model]
      )
    ]
  end

  defp get_finish_reason(%{"choices" => [%{"finish_reason" => r} | _]}), do: r
  defp get_finish_reason(_), do: "unknown"
end
