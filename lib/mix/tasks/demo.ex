defmodule Mix.Tasks.Demo do
  @moduledoc """
  Starts a demo server with sample data for screenshots.

  Usage:
      mix demo

  Opens http://localhost:4001/dashboard
  """
  use Mix.Task

  @requirements ["app.start"]

  def run(_args) do
    # Configure Phoenix endpoint
    Application.put_env(:req_llm_gateway, ReqLLMGateway.DemoEndpoint,
      http: [port: 4001],
      url: [host: "localhost"],
      secret_key_base: String.duplicate("a", 64),
      live_view: [signing_salt: "demo_salt"],
      server: true,
      debug_errors: true,
      check_origin: false
    )

    # Start the application
    {:ok, _} = Application.ensure_all_started(:req_llm_gateway)

    # Start the Phoenix endpoint
    {:ok, _} = ReqLLMGateway.DemoEndpoint.start_link()

    # Give it a moment to start
    Process.sleep(1000)

    # Populate sample data
    populate_demo_data()

    # Instructions
    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("🚀 Demo server running!")
    IO.puts(String.duplicate("=", 60))
    IO.puts("\n🌐 LiveDashboard: http://localhost:4001/dashboard")
    IO.puts("   Click 'LLM Usage' tab to see the stats")
    IO.puts("\n📊 Gateway endpoint: http://localhost:4001/v1/chat/completions")
    IO.puts("📈 Usage stats in terminal above")
    IO.puts("\nPress Ctrl+C to stop\n")

    # Keep running
    Process.sleep(:infinity)
  end

  defp populate_demo_data do
    alias ReqLLMGateway.Usage

    IO.puts("\n📝 Populating demo data...")

    # Realistic test data
    test_data = [
      {"openai", "gpt-4o", 12, 15_234, 4_892, 0.10115, 450},
      {"openai", "gpt-4o-mini", 28, 42_150, 12_840, 0.01401, 320},
      {"anthropic", "claude-3-5-sonnet-20241022", 18, 28_945, 9_234, 0.22567, 680},
      {"anthropic", "claude-3-haiku-20240307", 45, 67_890, 18_450, 0.02851, 290},
      {"google", "gemini-1.5-pro", 8, 19_234, 6_123, 0.08934, 550},
      {"groq", "llama3-70b", 15, 28_345, 8_234, 0.00000, 180}
    ]

    Enum.each(test_data, fn {provider, model, calls, prompt, completion, cost, latency} ->
      Enum.each(1..calls, fn _ ->
        usage = %{
          "prompt_tokens" => div(prompt, calls),
          "completion_tokens" => div(completion, calls),
          "total_tokens" => div(prompt + completion, calls),
          "cost_usd" => cost / calls
        }

        Usage.record(provider, model, usage, latency + Enum.random(-50..50))
      end)
    end)

    IO.puts("✅ Demo data populated!\n")
    IO.puts("📊 Current usage stats:\n")

    stats = Usage.get_all()

    # Print header
    IO.puts(String.pad_trailing("Provider", 12) <>
            String.pad_trailing("Model", 35) <>
            String.pad_leading("Calls", 8) <>
            String.pad_leading("Tokens", 12) <>
            String.pad_leading("Cost", 12) <>
            String.pad_leading("Latency", 10))
    IO.puts(String.duplicate("-", 89))

    # Print each row
    Enum.each(stats, fn s ->
      IO.puts(
        String.pad_trailing(s.provider, 12) <>
        String.pad_trailing(s.model, 35) <>
        String.pad_leading(Integer.to_string(s.calls), 8) <>
        String.pad_leading(format_number(s.total_tokens), 12) <>
        String.pad_leading("$#{Float.round(s.cost_usd, 4)}", 12) <>
        String.pad_leading("#{s.avg_latency_ms}ms", 10)
      )
    end)

    total_cost = stats |> Enum.map(& &1.cost_usd) |> Enum.sum()
    total_tokens = stats |> Enum.map(& &1.total_tokens) |> Enum.sum()
    total_calls = stats |> Enum.map(& &1.calls) |> Enum.sum()

    IO.puts(String.duplicate("-", 89))
    IO.puts(String.pad_trailing("TOTAL", 47) <>
            String.pad_leading(Integer.to_string(total_calls), 8) <>
            String.pad_leading(format_number(total_tokens), 12) <>
            String.pad_leading("$#{Float.round(total_cost, 4)}", 12))
  end

  defp format_number(num) when is_integer(num) do
    num
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end
end
