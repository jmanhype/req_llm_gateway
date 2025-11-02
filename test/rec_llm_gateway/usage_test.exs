defmodule RecLLMGateway.UsageTest do
  use ExUnit.Case

  alias RecLLMGateway.Usage

  setup do
    # Start the Usage GenServer for tests
    start_supervised!(Usage)
    # Clear any existing data
    Usage.clear_all()
    :ok
  end

  describe "record/4" do
    test "records usage correctly" do
      usage = %{
        "prompt_tokens" => 100,
        "completion_tokens" => 50,
        "total_tokens" => 150,
        "cost_usd" => 0.001
      }

      assert :ok = Usage.record("openai", "gpt-4", usage, 250)

      records = Usage.get_all()
      assert length(records) == 1

      [record] = records
      assert record.provider == "openai"
      assert record.model == "gpt-4"
      assert record.calls == 1
      assert record.prompt_tokens == 100
      assert record.completion_tokens == 50
      assert record.total_tokens == 150
      assert record.cost_usd == 0.001
      assert record.avg_latency_ms == 250
    end

    test "accumulates multiple calls" do
      usage1 = %{"prompt_tokens" => 100, "completion_tokens" => 50, "cost_usd" => 0.001}
      usage2 = %{"prompt_tokens" => 200, "completion_tokens" => 100, "cost_usd" => 0.002}

      Usage.record("openai", "gpt-4", usage1, 250)
      Usage.record("openai", "gpt-4", usage2, 350)

      [record] = Usage.get_all()
      assert record.calls == 2
      assert record.prompt_tokens == 300
      assert record.completion_tokens == 150
      assert record.total_tokens == 450
      assert record.cost_usd == 0.003
      assert record.avg_latency_ms == 300
    end

    test "tracks different models separately" do
      usage = %{"prompt_tokens" => 100, "completion_tokens" => 50, "cost_usd" => 0.001}

      Usage.record("openai", "gpt-4", usage, 250)
      Usage.record("openai", "gpt-3.5-turbo", usage, 150)

      records = Usage.get_all()
      assert length(records) == 2
    end

    test "handles missing cost gracefully" do
      usage = %{"prompt_tokens" => 100, "completion_tokens" => 50}

      assert :ok = Usage.record("openai", "gpt-4", usage, 250)

      [record] = Usage.get_all()
      assert record.cost_usd == 0.0
    end
  end

  describe "get_by_date/1" do
    test "filters by date" do
      today = Date.utc_today()
      usage = %{"prompt_tokens" => 100, "completion_tokens" => 50}

      Usage.record("openai", "gpt-4", usage, 250)

      records = Usage.get_by_date(today)
      assert length(records) == 1
    end
  end

  describe "get_by_provider/1" do
    test "filters by provider" do
      usage = %{"prompt_tokens" => 100, "completion_tokens" => 50}

      Usage.record("openai", "gpt-4", usage, 250)
      Usage.record("anthropic", "claude-3-sonnet", usage, 300)

      records = Usage.get_by_provider("openai")
      assert length(records) == 1
      assert hd(records).provider == "openai"
    end
  end
end
