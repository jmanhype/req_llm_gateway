defmodule RecLLMGateway.LiveDashboard do
  @moduledoc """
  LiveDashboard page for viewing usage statistics.

  ## Usage

  Add to your Phoenix endpoint's LiveDashboard:

      live_dashboard "/dashboard",
        additional_pages: [
          rec_llm: RecLLMGateway.LiveDashboard
        ]
  """

  use Phoenix.LiveDashboard.PageBuilder

  @impl true
  def menu_link(_, _) do
    {:ok, "LLM Usage"}
  end

  @impl true
  def render_page(_assigns) do
    table(
      columns: table_columns(),
      id: :usage_table,
      row_attrs: &row_attrs/1,
      row_fetcher: &fetch_usage/2,
      rows_name: "usage records",
      title: "LLM Gateway Usage"
    )
  end

  defp table_columns do
    [
      %{
        field: :date,
        header: "Date",
        format: &format_date/1
      },
      %{
        field: :provider,
        header: "Provider"
      },
      %{
        field: :model,
        header: "Model"
      },
      %{
        field: :calls,
        header: "Calls",
        header_attrs: [class: "text-right"],
        cell_attrs: [class: "tabular-nums text-right"]
      },
      %{
        field: :prompt_tokens,
        header: "Prompt Tokens",
        header_attrs: [class: "text-right"],
        cell_attrs: [class: "tabular-nums text-right"],
        format: &format_number/1
      },
      %{
        field: :completion_tokens,
        header: "Completion Tokens",
        header_attrs: [class: "text-right"],
        cell_attrs: [class: "tabular-nums text-right"],
        format: &format_number/1
      },
      %{
        field: :total_tokens,
        header: "Total Tokens",
        header_attrs: [class: "text-right"],
        cell_attrs: [class: "tabular-nums text-right"],
        format: &format_number/1
      },
      %{
        field: :cost_usd,
        header: "Cost (USD)",
        header_attrs: [class: "text-right"],
        cell_attrs: [class: "tabular-nums text-right"],
        format: &format_cost/1
      },
      %{
        field: :avg_latency_ms,
        header: "Avg Latency (ms)",
        header_attrs: [class: "text-right"],
        cell_attrs: [class: "tabular-nums text-right"]
      }
    ]
  end

  defp fetch_usage(params, _node) do
    %{sort_by: sort_by, sort_dir: sort_dir, limit: limit} = params

    records = RecLLMGateway.Usage.get_all()

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
    [
      {"phx-click", "show_details"},
      {"phx-value-date", to_string(record.date)},
      {"phx-value-provider", record.provider},
      {"phx-value-model", record.model}
    ]
  end

  defp format_date(date), do: Date.to_string(date)

  defp format_number(num) when is_integer(num) do
    num
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end

  defp format_number(num), do: to_string(num)

  defp format_cost(cost) when is_float(cost) or is_integer(cost) do
    "$#{:erlang.float_to_binary(cost * 1.0, decimals: 6)}"
  end

  defp format_cost(_), do: "$0.000000"
end
