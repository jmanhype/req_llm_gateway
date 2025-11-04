defmodule ReqLLMGateway.LiveDashboardOptimizer do
  @moduledoc """
  LiveDashboard page for viewing AI optimization recommendations.

  ## Usage

  Add to your Phoenix endpoint's LiveDashboard:

      live_dashboard "/dashboard",
        additional_pages: [
          req_llm: ReqLLMGateway.LiveDashboard,
          optimizer: ReqLLMGateway.LiveDashboardOptimizer
        ]
  """

  use Phoenix.LiveDashboard.PageBuilder

  @impl true
  def menu_link(_, _) do
    {:ok, "AI Optimizer"}
  end

  @impl true
  def render_page(_assigns) do
    table(
      columns: table_columns(),
      id: :optimizer_table,
      row_attrs: &row_attrs/1,
      row_fetcher: &fetch_recommendations/2,
      rows_name: "recommendations",
      title: "AI Optimization Recommendations"
    )
  end

  defp table_columns do
    [
      %{
        field: :priority,
        header: "Priority",
        format: &format_priority/1
      },
      %{
        field: :type,
        header: "Type",
        format: &format_type/1
      },
      %{
        field: :description,
        header: "Recommendation"
      },
      %{
        field: :impact_estimate,
        header: "Impact",
        format: &format_impact/1
      },
      %{
        field: :date,
        header: "Date",
        format: &format_date/1
      }
    ]
  end

  defp fetch_recommendations(params, _node) do
    %{sort_by: sort_by, sort_dir: sort_dir, limit: limit} = params

    records = ReqLLMGateway.AutoOptimizer.get_recommendations()

    # Sort
    sorted =
      Enum.sort_by(
        records,
        &Map.get(&1, sort_by),
        if(sort_dir == :desc, do: :desc, else: :asc)
      )

    # Paginate
    paginated = Enum.take(sorted, limit)

    {paginated, length(records)}
  end

  defp row_attrs(record) do
    priority_class =
      case record.priority do
        1 -> "bg-red-50"
        2 -> "bg-orange-50"
        3 -> "bg-yellow-50"
        _ -> ""
      end

    [
      {"class", priority_class},
      {"phx-click", "show_recommendation_details"},
      {"phx-value-id", to_string(record.id)}
    ]
  end

  defp format_date(date), do: Date.to_string(date)

  defp format_priority(1), do: "🔴 Critical"
  defp format_priority(2), do: "🟠 High"
  defp format_priority(3), do: "🟡 Medium"
  defp format_priority(4), do: "🟢 Low"
  defp format_priority(_), do: "Unknown"

  defp format_type(:cost_optimization), do: "💰 Cost"
  defp format_type(:performance), do: "⚡ Performance"
  defp format_type(:reliability), do: "🔒 Reliability"
  defp format_type(type), do: to_string(type)

  defp format_impact(impact) when is_map(impact) do
    cond do
      Map.has_key?(impact, :cost_savings_percent) ->
        "Save #{Float.round(impact.cost_savings_percent, 1)}% ($#{Float.round(impact.estimated_savings_usd, 2)})"

      Map.has_key?(impact, :latency_overhead_ms) ->
        "Reduce latency by #{round(impact.latency_overhead_ms)}ms"

      Map.has_key?(impact, :variability_ratio) ->
        "Variability: #{Float.round(impact.variability_ratio, 1)}x"

      true ->
        inspect(impact)
    end
  end

  defp format_impact(_), do: "-"
end
