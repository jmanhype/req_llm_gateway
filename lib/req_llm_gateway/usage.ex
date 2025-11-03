defmodule ReqLLMGateway.Usage do
  @moduledoc """
  In-memory usage tracking with ETS.

  Tracks token usage, costs, and latency per {date, provider, model} tuple.
  Data is stored in ETS and persists for the lifetime of the application.

  ## Schema

  Key: `{date, provider, model}` where date is a Date struct

  Value: `{calls, prompt_tokens, completion_tokens, total_tokens, cost_micro_usd, latency_ms_total}`

  ## Examples

      ReqLLMGateway.Usage.record("openai", "gpt-4", %{"prompt_tokens" => 10, "completion_tokens" => 20, "cost_usd" => 0.001}, 250)

      ReqLLMGateway.Usage.get_all()
      #=> [
      #  %{
      #    date: ~D[2024-01-15],
      #    provider: "openai",
      #    model: "gpt-4",
      #    calls: 1,
      #    prompt_tokens: 10,
      #    completion_tokens: 20,
      #    total_tokens: 30,
      #    cost_usd: 0.001,
      #    avg_latency_ms: 250
      #  }
      #]
  """

  use GenServer
  require Logger

  @table_name :req_llm_gateway_usage

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Records usage for a request.

  - `provider` - The LLM provider (e.g., "openai", "anthropic")
  - `model` - The model name (e.g., "gpt-4", "claude-3-sonnet")
  - `usage` - Map with "prompt_tokens", "completion_tokens", "total_tokens", and optionally "cost_usd"
  - `latency_ms` - Request latency in milliseconds
  """
  def record(provider, model, usage, latency_ms) do
    date = Date.utc_today()
    key = {date, provider, model}

    prompt_tokens = Map.get(usage, "prompt_tokens", 0)
    completion_tokens = Map.get(usage, "completion_tokens", 0)
    total_tokens = Map.get(usage, "total_tokens", prompt_tokens + completion_tokens)

    cost_micro =
      case Map.get(usage, "cost_usd") do
        nil -> 0
        cost when is_number(cost) -> round(cost * 1_000_000)
        _ -> 0
      end

    :ets.update_counter(
      @table_name,
      key,
      [
        {2, 1},
        # calls
        {3, prompt_tokens},
        # prompt_tokens
        {4, completion_tokens},
        # completion_tokens
        {5, total_tokens},
        # total_tokens
        {6, cost_micro},
        # cost_micro_usd
        {7, latency_ms}
        # latency_ms_total
      ],
      {key, 0, 0, 0, 0, 0, 0}
    )

    :ok
  rescue
    error ->
      Logger.error("Failed to record usage: #{inspect(error)}")
      :ok
  end

  @doc """
  Gets all usage records as a list of maps.
  """
  def get_all do
    @table_name
    |> :ets.tab2list()
    |> Enum.map(&format_record/1)
    |> Enum.sort_by(fn r -> {r.date, r.provider, r.model} end, :desc)
  end

  @doc """
  Gets usage records for a specific date.
  """
  def get_by_date(date) do
    @table_name
    |> :ets.match_object({{date, :_, :_}, :_, :_, :_, :_, :_, :_})
    |> Enum.map(&format_record/1)
  end

  @doc """
  Gets usage records for a specific provider.
  """
  def get_by_provider(provider) do
    @table_name
    |> :ets.match_object({{:_, provider, :_}, :_, :_, :_, :_, :_, :_})
    |> Enum.map(&format_record/1)
  end

  @doc """
  Clears all usage data.
  """
  def clear_all do
    :ets.delete_all_objects(@table_name)
    :ok
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    table =
      :ets.new(@table_name, [
        :named_table,
        :public,
        :set,
        read_concurrency: true,
        write_concurrency: true
      ])

    Logger.info("Started ReqLLMGateway.Usage ETS table: #{inspect(table)}")
    {:ok, %{}}
  end

  # Helpers

  defp format_record(
         {{date, provider, model}, calls, prompt_tokens, completion_tokens, total_tokens,
          cost_micro, latency_ms_total}
       ) do
    %{
      date: date,
      provider: provider,
      model: model,
      calls: calls,
      prompt_tokens: prompt_tokens,
      completion_tokens: completion_tokens,
      total_tokens: total_tokens,
      cost_usd: cost_micro / 1_000_000,
      avg_latency_ms: if(calls > 0, do: div(latency_ms_total, calls), else: 0)
    }
  end
end
