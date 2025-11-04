defmodule ReqLLMGateway.AutoOptimizer do
  @moduledoc """
  AI-driven self-improvement module for the LLM gateway.

  This module analyzes usage patterns, provider performance, and costs to provide
  intelligent recommendations for optimizing the gateway's operation.

  ## Features

  - Cost optimization analysis
  - Provider performance monitoring
  - Reliability pattern detection
  - Intelligent routing recommendations
  - Automated anomaly detection

  ## Architecture

  The AutoOptimizer runs periodic analysis tasks that:
  1. Collect data from ReqLLMGateway.Usage ETS table
  2. Analyze patterns and trends
  3. Generate actionable recommendations
  4. Store optimization insights for dashboard display

  ## Data Storage

  Recommendations are stored in an ETS table with the following schema:
  - Key: `{date, recommendation_type}`
  - Value: `{priority, description, impact_estimate, metadata}`

  ## Usage

      # Run analysis manually
      ReqLLMGateway.AutoOptimizer.run_analysis()

      # Get current recommendations
      ReqLLMGateway.AutoOptimizer.get_recommendations()

      # Get cost optimization opportunities
      ReqLLMGateway.AutoOptimizer.analyze_cost_opportunities()
  """

  use GenServer
  require Logger

  alias ReqLLMGateway.{Usage, Pricing}

  @table_name :req_llm_gateway_optimizer
  @recommendations_table :req_llm_gateway_recommendations

  # Recommendation priorities
  @priority_critical 1
  @priority_high 2
  @priority_medium 3
  @priority_low 4

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Runs a full analysis cycle and generates recommendations.
  """
  def run_analysis do
    GenServer.call(__MODULE__, :run_analysis, 30_000)
  end

  @doc """
  Gets all current recommendations.
  """
  def get_recommendations do
    @recommendations_table
    |> :ets.tab2list()
    |> Enum.map(&format_recommendation/1)
    |> Enum.sort_by(& &1.priority)
  end

  @doc """
  Gets recommendations for a specific type.
  """
  def get_recommendations_by_type(type) do
    @recommendations_table
    |> :ets.match_object({{:_, type}, :_, :_, :_, :_})
    |> Enum.map(&format_recommendation/1)
    |> Enum.sort_by(& &1.priority)
  end

  @doc """
  Analyzes cost optimization opportunities.

  Returns a list of recommendations for reducing costs based on:
  - High-cost provider usage
  - Availability of cheaper alternatives
  - Usage patterns that could benefit from different models
  """
  def analyze_cost_opportunities do
    usage_data = Usage.get_all()

    usage_data
    |> identify_high_cost_providers()
    |> suggest_cheaper_alternatives()
    |> format_cost_recommendations()
  end

  @doc """
  Analyzes provider performance trends.

  Returns insights about:
  - Average latency by provider
  - Latency trends over time
  - Performance degradation alerts
  """
  def analyze_performance_trends do
    usage_data = Usage.get_all()

    usage_data
    |> calculate_latency_percentiles()
    |> identify_slow_providers()
    |> detect_performance_anomalies()
  end

  @doc """
  Analyzes reliability patterns based on usage data.

  Note: Error tracking requires integration with Plug to record failures.
  This provides analysis based on successful requests only.
  """
  def analyze_reliability_patterns do
    usage_data = Usage.get_all()

    usage_data
    |> group_by_provider()
    |> calculate_usage_distribution()
    |> identify_underutilized_providers()
  end

  @doc """
  Generates a comprehensive daily report.
  """
  def generate_daily_report do
    date = Date.utc_today()
    usage = Usage.get_by_date(date)

    %{
      date: date,
      summary: generate_summary(usage),
      cost_analysis: analyze_daily_costs(usage),
      performance_analysis: analyze_daily_performance(usage),
      recommendations: get_recommendations(),
      total_cost_usd: Enum.sum(Enum.map(usage, & &1.cost_usd)),
      total_tokens: Enum.sum(Enum.map(usage, & &1.total_tokens)),
      total_requests: Enum.sum(Enum.map(usage, & &1.calls))
    }
  end

  @doc """
  Recommends the best provider for a given model based on learned patterns.

  Takes into account:
  - Historical latency
  - Cost efficiency
  - Recent performance
  """
  def recommend_provider(model, constraints \\ %{}) do
    usage_data = Usage.get_all()

    usage_data
    |> filter_by_model(model)
    |> score_providers(constraints)
    |> select_best_provider()
  end

  @doc """
  Gets model alternatives for cost optimization.
  """
  def get_model_alternatives(provider, model) do
    current_usage = find_model_usage(provider, model)

    if current_usage do
      find_cheaper_alternatives(current_usage)
    else
      []
    end
  end

  @doc """
  Records additional metadata for learning (e.g., user feedback, quality scores).
  """
  def record_feedback(request_id, quality_score, feedback_text \\ nil) do
    GenServer.cast(__MODULE__, {:record_feedback, request_id, quality_score, feedback_text})
  end

  @doc """
  Clears all recommendations.
  """
  def clear_recommendations do
    :ets.delete_all_objects(@recommendations_table)
    :ok
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    # Create optimizer data table
    :ets.new(@table_name, [
      :named_table,
      :public,
      :set,
      read_concurrency: true,
      write_concurrency: true
    ])

    # Create recommendations table
    :ets.new(@recommendations_table, [
      :named_table,
      :public,
      :set,
      read_concurrency: true,
      write_concurrency: true
    ])

    # Get configuration
    config = Application.get_env(:req_llm_gateway, :auto_optimizer, [])
    enabled = Keyword.get(config, :enabled, true)
    interval = Keyword.get(config, :analysis_interval, 3600) * 1000

    state = %{
      enabled: enabled,
      analysis_interval: interval,
      last_analysis: nil,
      config: config
    }

    # Schedule first analysis if enabled
    if enabled do
      schedule_analysis(interval)
    end

    Logger.info("Started ReqLLMGateway.AutoOptimizer (enabled: #{enabled})")
    {:ok, state}
  end

  @impl true
  def handle_call(:run_analysis, _from, state) do
    result = perform_analysis(state.config)
    {:reply, result, %{state | last_analysis: DateTime.utc_now()}}
  end

  @impl true
  def handle_cast({:record_feedback, request_id, quality_score, feedback_text}, state) do
    # Store feedback for future learning
    feedback_data = %{
      request_id: request_id,
      quality_score: quality_score,
      feedback_text: feedback_text,
      timestamp: DateTime.utc_now()
    }

    :ets.insert(@table_name, {{:feedback, request_id}, feedback_data})
    {:noreply, state}
  end

  @impl true
  def handle_info(:run_analysis, state) do
    if state.enabled do
      perform_analysis(state.config)
      schedule_analysis(state.analysis_interval)
    end

    {:noreply, %{state | last_analysis: DateTime.utc_now()}}
  end

  # Private Functions

  defp schedule_analysis(interval) do
    Process.send_after(self(), :run_analysis, interval)
  end

  defp perform_analysis(config) do
    Logger.info("Running AutoOptimizer analysis...")

    try do
      # Run all analysis tasks
      cost_recs = analyze_cost_opportunities()
      perf_recs = analyze_performance_trends()
      reliability_recs = analyze_reliability_patterns()

      # Store recommendations
      store_recommendations(cost_recs, :cost_optimization)
      store_recommendations(perf_recs, :performance)
      store_recommendations(reliability_recs, :reliability)

      total_recs = length(cost_recs) + length(perf_recs) + length(reliability_recs)
      Logger.info("AutoOptimizer analysis complete: #{total_recs} recommendations generated")

      {:ok, total_recs}
    rescue
      error ->
        Logger.error("AutoOptimizer analysis failed: #{inspect(error)}")
        {:error, error}
    end
  end

  defp store_recommendations(recommendations, type) do
    Enum.each(recommendations, fn rec ->
      key = {Date.utc_today(), type, rec.id}
      value = {rec.priority, rec.description, rec.impact_estimate, rec.metadata}
      :ets.insert(@recommendations_table, {key, value})
    end)
  end

  defp identify_high_cost_providers(usage_data) do
    min_samples = Application.get_env(:req_llm_gateway, :auto_optimizer, [])
                  |> Keyword.get(:min_samples_for_analysis, 50)

    usage_data
    |> Enum.filter(fn record -> record.calls >= min_samples end)
    |> Enum.group_by(& &1.provider)
    |> Enum.map(fn {provider, records} ->
      total_cost = Enum.sum(Enum.map(records, & &1.cost_usd))
      total_tokens = Enum.sum(Enum.map(records, & &1.total_tokens))
      cost_per_1k = if total_tokens > 0, do: total_cost / total_tokens * 1000, else: 0

      %{provider: provider, records: records, total_cost: total_cost, cost_per_1k: cost_per_1k}
    end)
    |> Enum.sort_by(& &1.total_cost, :desc)
  end

  defp suggest_cheaper_alternatives(provider_costs) do
    # Get all providers and their average costs
    provider_avg_costs =
      Enum.map(provider_costs, fn %{provider: p, cost_per_1k: c} -> {p, c} end)
      |> Map.new()

    # For each provider, find cheaper alternatives
    Enum.map(provider_costs, fn provider_data ->
      cheaper =
        provider_avg_costs
        |> Enum.filter(fn {p, cost} ->
          p != provider_data.provider and cost < provider_data.cost_per_1k * 0.8
        end)
        |> Enum.map(fn {p, cost} ->
          savings = provider_data.cost_per_1k - cost
          savings_percent = savings / provider_data.cost_per_1k * 100
          %{provider: p, cost_per_1k: cost, savings_percent: savings_percent}
        end)

      Map.put(provider_data, :cheaper_alternatives, cheaper)
    end)
  end

  defp format_cost_recommendations(provider_analysis) do
    provider_analysis
    |> Enum.filter(fn p -> length(p.cheaper_alternatives) > 0 end)
    |> Enum.map(fn provider_data ->
      best_alternative = Enum.max_by(provider_data.cheaper_alternatives, & &1.savings_percent)

      %{
        id: "cost_#{provider_data.provider}_#{:erlang.phash2(provider_data)}",
        type: :cost_optimization,
        priority: calculate_priority(provider_data.total_cost, best_alternative.savings_percent),
        description:
          "High cost detected for #{provider_data.provider} ($#{Float.round(provider_data.total_cost, 2)}). " <>
            "Consider switching to #{best_alternative.provider} for #{Float.round(best_alternative.savings_percent, 1)}% savings.",
        impact_estimate: %{
          cost_savings_percent: best_alternative.savings_percent,
          estimated_savings_usd: provider_data.total_cost * best_alternative.savings_percent / 100
        },
        metadata: %{
          current_provider: provider_data.provider,
          recommended_provider: best_alternative.provider,
          current_cost_per_1k: provider_data.cost_per_1k,
          alternative_cost_per_1k: best_alternative.cost_per_1k
        }
      }
    end)
  end

  defp calculate_latency_percentiles(usage_data) do
    usage_data
    |> Enum.group_by(& &1.provider)
    |> Enum.map(fn {provider, records} ->
      latencies = Enum.map(records, & &1.avg_latency_ms)
      sorted_latencies = Enum.sort(latencies)
      count = length(sorted_latencies)

      p50 = percentile(sorted_latencies, 0.5)
      p95 = percentile(sorted_latencies, 0.95)
      p99 = percentile(sorted_latencies, 0.99)

      %{
        provider: provider,
        count: count,
        p50: p50,
        p95: p95,
        p99: p99,
        avg: Enum.sum(latencies) / count
      }
    end)
  end

  defp identify_slow_providers(latency_data) do
    avg_p95 = latency_data |> Enum.map(& &1.p95) |> Enum.sum() |> Kernel./(length(latency_data))

    slow_providers =
      latency_data
      |> Enum.filter(fn p -> p.p95 > avg_p95 * 1.5 end)

    Enum.map(slow_providers, fn provider ->
      %{
        id: "perf_#{provider.provider}_#{:erlang.phash2(provider)}",
        type: :performance,
        priority: @priority_medium,
        description:
          "Provider #{provider.provider} has high latency (p95: #{round(provider.p95)}ms vs avg: #{round(avg_p95)}ms)",
        impact_estimate: %{
          latency_overhead_ms: provider.p95 - avg_p95,
          affected_requests: provider.count
        },
        metadata: provider
      }
    end)
  end

  defp detect_performance_anomalies(latency_data) do
    # Detect providers with large variance between p50 and p95 (inconsistent performance)
    Enum.filter(latency_data, fn p ->
      p.p95 > p.p50 * 3
    end)
    |> Enum.map(fn provider ->
      %{
        id: "anomaly_#{provider.provider}_#{:erlang.phash2(provider)}",
        type: :performance,
        priority: @priority_low,
        description:
          "Provider #{provider.provider} shows inconsistent latency (p50: #{round(provider.p50)}ms, p95: #{round(provider.p95)}ms)",
        impact_estimate: %{
          variability_ratio: provider.p95 / provider.p50
        },
        metadata: provider
      }
    end)
  end

  defp group_by_provider(usage_data) do
    Enum.group_by(usage_data, & &1.provider)
  end

  defp calculate_usage_distribution(grouped_data) do
    total_calls = grouped_data |> Enum.flat_map(fn {_, records} -> records end) |> Enum.sum_by(& &1.calls)

    Enum.map(grouped_data, fn {provider, records} ->
      provider_calls = Enum.sum_by(records, & &1.calls)
      usage_percent = if total_calls > 0, do: provider_calls / total_calls * 100, else: 0

      %{provider: provider, calls: provider_calls, usage_percent: usage_percent}
    end)
  end

  defp identify_underutilized_providers(usage_distribution) do
    # Identify providers with very low usage that might indicate issues
    Enum.filter(usage_distribution, fn p -> p.usage_percent < 5 and p.calls > 0 end)
    |> Enum.map(fn provider ->
      %{
        id: "util_#{provider.provider}_#{:erlang.phash2(provider)}",
        type: :reliability,
        priority: @priority_low,
        description:
          "Provider #{provider.provider} has low usage (#{Float.round(provider.usage_percent, 1)}%). " <>
            "Consider investigating if this indicates reliability issues.",
        impact_estimate: %{
          current_usage_percent: provider.usage_percent
        },
        metadata: provider
      }
    end)
  end

  defp generate_summary(usage_records) do
    total_requests = Enum.sum(Enum.map(usage_records, & &1.calls))
    total_cost = Enum.sum(Enum.map(usage_records, & &1.cost_usd))
    total_tokens = Enum.sum(Enum.map(usage_records, & &1.total_tokens))

    providers = usage_records |> Enum.map(& &1.provider) |> Enum.uniq() |> length()
    models = usage_records |> Enum.map(& &1.model) |> Enum.uniq() |> length()

    %{
      total_requests: total_requests,
      total_cost_usd: total_cost,
      total_tokens: total_tokens,
      unique_providers: providers,
      unique_models: models,
      avg_cost_per_request: if(total_requests > 0, do: total_cost / total_requests, else: 0)
    }
  end

  defp analyze_daily_costs(usage_records) do
    by_provider =
      usage_records
      |> Enum.group_by(& &1.provider)
      |> Enum.map(fn {provider, records} ->
        cost = Enum.sum(Enum.map(records, & &1.cost_usd))
        {provider, cost}
      end)
      |> Enum.sort_by(fn {_, cost} -> cost end, :desc)

    %{
      by_provider: by_provider,
      highest_cost_provider: List.first(by_provider),
      cost_distribution: Enum.map(by_provider, fn {p, c} -> %{provider: p, cost_usd: c} end)
    }
  end

  defp analyze_daily_performance(usage_records) do
    by_provider =
      usage_records
      |> Enum.group_by(& &1.provider)
      |> Enum.map(fn {provider, records} ->
        avg_latency = Enum.sum(Enum.map(records, & &1.avg_latency_ms)) / length(records)
        {provider, avg_latency}
      end)
      |> Enum.sort_by(fn {_, latency} -> latency end)

    %{
      by_provider: by_provider,
      fastest_provider: List.first(by_provider),
      slowest_provider: List.last(by_provider)
    }
  end

  defp filter_by_model(usage_data, model) do
    Enum.filter(usage_data, fn record ->
      String.contains?(record.model, model) or record.model == model
    end)
  end

  defp score_providers(usage_data, constraints) do
    max_latency = Map.get(constraints, :max_latency_ms)
    max_cost_per_1k = Map.get(constraints, :max_cost_per_1k_tokens)

    usage_data
    |> Enum.group_by(& &1.provider)
    |> Enum.map(fn {provider, records} ->
      avg_latency = Enum.sum(Enum.map(records, & &1.avg_latency_ms)) / length(records)
      total_tokens = Enum.sum(Enum.map(records, & &1.total_tokens))
      total_cost = Enum.sum(Enum.map(records, & &1.cost_usd))
      cost_per_1k = if total_tokens > 0, do: total_cost / total_tokens * 1000, else: 999_999

      # Apply constraint filters
      meets_latency = is_nil(max_latency) or avg_latency <= max_latency
      meets_cost = is_nil(max_cost_per_1k) or cost_per_1k <= max_cost_per_1k

      # Simple scoring: lower cost and lower latency is better
      score = if meets_latency and meets_cost do
        1000 - cost_per_1k - avg_latency / 100
      else
        -999_999
      end

      %{
        provider: provider,
        score: score,
        avg_latency_ms: avg_latency,
        cost_per_1k_tokens: cost_per_1k,
        sample_size: length(records)
      }
    end)
    |> Enum.filter(fn p -> p.score > 0 end)
  end

  defp select_best_provider(scored_providers) do
    case Enum.max_by(scored_providers, & &1.score, fn -> nil end) do
      nil -> {:error, :no_suitable_provider}
      provider -> {:ok, provider}
    end
  end

  defp find_model_usage(provider, model) do
    Usage.get_all()
    |> Enum.find(fn record ->
      record.provider == provider and record.model == model
    end)
  end

  defp find_cheaper_alternatives(current_usage) do
    current_cost_per_1k =
      if current_usage.total_tokens > 0,
        do: current_usage.cost_usd / current_usage.total_tokens * 1000,
        else: 0

    Usage.get_all()
    |> Enum.reject(fn record ->
      record.provider == current_usage.provider and record.model == current_usage.model
    end)
    |> Enum.map(fn record ->
      cost_per_1k = if record.total_tokens > 0, do: record.cost_usd / record.total_tokens * 1000, else: 0

      %{
        provider: record.provider,
        model: record.model,
        cost_per_1k_tokens: cost_per_1k,
        savings_percent: (current_cost_per_1k - cost_per_1k) / current_cost_per_1k * 100,
        avg_latency_ms: record.avg_latency_ms
      }
    end)
    |> Enum.filter(fn alt -> alt.cost_per_1k_tokens < current_cost_per_1k * 0.9 end)
    |> Enum.sort_by(& &1.savings_percent, :desc)
    |> Enum.take(5)
  end

  defp calculate_priority(total_cost, savings_percent) do
    cond do
      total_cost > 100 and savings_percent > 30 -> @priority_critical
      total_cost > 50 and savings_percent > 20 -> @priority_high
      total_cost > 10 and savings_percent > 15 -> @priority_medium
      true -> @priority_low
    end
  end

  defp percentile(sorted_list, p) when p >= 0 and p <= 1 do
    count = length(sorted_list)
    if count == 0 do
      0
    else
      index = round((count - 1) * p)
      Enum.at(sorted_list, index)
    end
  end

  defp format_recommendation(
         {{date, type, id}, {priority, description, impact_estimate, metadata}}
       ) do
    %{
      id: id,
      date: date,
      type: type,
      priority: priority,
      description: description,
      impact_estimate: impact_estimate,
      metadata: metadata
    }
  end
end
