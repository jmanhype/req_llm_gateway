defmodule ReqLLMGateway.PricingTest do
  use ExUnit.Case, async: true

  alias ReqLLMGateway.Pricing

  describe "calculate/2" do
    test "calculates cost for gpt-4" do
      usage = %{"prompt_tokens" => 1000, "completion_tokens" => 500}
      # (1000/1M * 30) + (500/1M * 60) = 0.03 + 0.03 = 0.06
      assert Pricing.calculate("gpt-4", usage) == 0.06
    end

    test "calculates cost for gpt-4o-mini" do
      usage = %{"prompt_tokens" => 10_000, "completion_tokens" => 5_000}
      # (10000/1M * 0.15) + (5000/1M * 0.6) = 0.0015 + 0.003 = 0.0045
      assert Pricing.calculate("gpt-4o-mini", usage) == 0.0045
    end

    test "calculates cost for claude-3-sonnet" do
      usage = %{"prompt_tokens" => 1000, "completion_tokens" => 500}
      # (1000/1M * 3) + (500/1M * 15) = 0.003 + 0.0075 = 0.0105
      assert Pricing.calculate("claude-3-sonnet", usage) == 0.0105
    end

    test "returns nil for unknown model" do
      usage = %{"prompt_tokens" => 1000, "completion_tokens" => 500}
      assert Pricing.calculate("unknown-model", usage) == nil
    end

    test "returns nil for missing token counts" do
      assert Pricing.calculate("gpt-4", %{}) == nil
      assert Pricing.calculate("gpt-4", %{"prompt_tokens" => 100}) == nil
    end

    test "returns nil for invalid input" do
      assert Pricing.calculate("gpt-4", nil) == nil
      assert Pricing.calculate("gpt-4", "not a map") == nil
    end
  end

  describe "get_model_pricing/1" do
    test "returns pricing for known models" do
      assert %{input: 30.0, output: 60.0} = Pricing.get_model_pricing("gpt-4")
      assert %{input: 0.15, output: 0.6} = Pricing.get_model_pricing("gpt-4o-mini")
    end

    test "returns nil for unknown models" do
      assert Pricing.get_model_pricing("unknown-model") == nil
    end
  end
end
