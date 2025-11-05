defmodule ReqLLMGateway.LiveDashboard do
  @moduledoc """
  LiveDashboard page for viewing usage statistics.
  """
  use Phoenix.LiveDashboard.PageBuilder

  @impl true
  def menu_link(_, _) do
    {:ok, "LLM Usage"}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h5 class="card-title">LLM Gateway Usage</h5>
      <div class="card tabular-card mb-4 mt-4">
        <div class="card-body p-0">
          <div class="dash-table-wrapper">
            <%= render_table(assigns) %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_table(assigns) do
    # Limit to 200 most recent records to prevent memory exhaustion
    # For full history, export data via API or database
    assigns = assign(assigns, :records, ReqLLMGateway.Usage.get_all(limit: 200))

    ~H"""
    <table class="table table-hover mt-0 mb-0">
      <thead>
        <tr>
          <th class="pl-4">Date</th>
          <th>Provider</th>
          <th>Model</th>
          <th class="text-right">Calls</th>
          <th class="text-right">Prompt Tokens</th>
          <th class="text-right">Completion Tokens</th>
          <th class="text-right">Total Tokens</th>
          <th class="text-right">Cost (USD)</th>
          <th class="text-right pr-4">Avg Latency (ms)</th>
        </tr>
      </thead>
      <tbody>
        <%= for record <- @records do %>
          <tr>
            <td class="tabular-column-name pl-4"><%= Date.to_string(record.date) %></td>
            <td class="tabular-column-name"><%= record.provider %></td>
            <td class="tabular-column-name"><%= record.model %></td>
            <td class="tabular-column-value text-right"><%= record.calls %></td>
            <td class="tabular-column-value text-right"><%= format_number(record.prompt_tokens) %></td>
            <td class="tabular-column-value text-right"><%= format_number(record.completion_tokens) %></td>
            <td class="tabular-column-value text-right"><%= format_number(record.total_tokens) %></td>
            <td class="tabular-column-value text-right"><%= format_cost(record.cost_usd) %></td>
            <td class="tabular-column-value text-right pr-4"><%= record.avg_latency_ms %>ms</td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  defp format_number(num) when is_integer(num) do
    num
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end

  defp format_cost(cost) when is_float(cost) do
    "$#{:erlang.float_to_binary(cost, decimals: 6)}"
  end

  defp format_cost(_), do: "$0.000000"
end
