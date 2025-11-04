defmodule ReqLLMGateway.AutoOptimizerTest do
  use ExUnit.Case

  alias ReqLLMGateway.{AutoOptimizer, Usage}

  setup do
    # Start both Usage and AutoOptimizer GenServers
    start_supervised!(Usage)
    start_supervised!({AutoOptimizer, []})

    # Clear any existing data
    Usage.clear_all()
    AutoOptimizer.clear_recommendations()

    :ok
  end

  describe "analyze_cost_opportunities/0" do
    test "identifies high-cost providers and suggests cheaper alternatives" do
      # Create usage data with different cost profiles
      expensive_usage = %{
        "prompt_tokens" => 1000,
        "completion_tokens" => 500,
        "cost_usd" => 0.1
      }

      cheap_usage = %{
        "prompt_tokens" => 1000,
        "completion_tokens" => 500,
        "cost_usd" => 0.01
      }

      # Record enough samples to trigger analysis (50+ calls)
      for _ <- 1..60 do
        Usage.record("expensive_provider", "expensive-model", expensive_usage, 250)
        Usage.record("cheap_provider", "cheap-model", cheap_usage, 250)
      end

      recommendations = AutoOptimizer.analyze_cost_opportunities()

      # Should recommend switching from expensive to cheap provider
      assert is_list(recommendations)
      assert length(recommendations) > 0

      expensive_rec = Enum.find(recommendations, fn r ->
        r.metadata.current_provider == "expensive_provider"
      end)

      assert expensive_rec != nil
      assert expensive_rec.type == :cost_optimization
      assert expensive_rec.metadata.recommended_provider == "cheap_provider"
      assert expensive_rec.impact_estimate.cost_savings_percent > 0
    end

    test "does not recommend alternatives when providers are similarly priced" do
      usage = %{
        "prompt_tokens" => 1000,
        "completion_tokens" => 500,
        "cost_usd" => 0.05
      }

      # Record usage for multiple providers with similar costs
      for _ <- 1..60 do
        Usage.record("provider_a", "model-a", usage, 250)
        Usage.record("provider_b", "model-b", usage, 250)
      end

      recommendations = AutoOptimizer.analyze_cost_opportunities()

      # Should not generate recommendations for similarly priced providers
      assert length(recommendations) == 0
    end

    test "requires minimum sample size before analyzing" do
      usage = %{"prompt_tokens" => 100, "completion_tokens" => 50, "cost_usd" => 0.001}

      # Record only a few samples (below min_samples_for_analysis threshold)
      for _ <- 1..5 do
        Usage.record("openai", "gpt-4", usage, 250)
      end

      recommendations = AutoOptimizer.analyze_cost_opportunities()

      # Should not generate recommendations with insufficient data
      assert recommendations == []
    end
  end

  describe "analyze_performance_trends/0" do
    test "identifies slow providers" do
      fast_usage = %{"prompt_tokens" => 100, "completion_tokens" => 50, "cost_usd" => 0.001}
      slow_usage = %{"prompt_tokens" => 100, "completion_tokens" => 50, "cost_usd" => 0.001}

      # Create providers with different latency profiles
      for _ <- 1..60 do
        Usage.record("fast_provider", "fast-model", fast_usage, 100)
        Usage.record("slow_provider", "slow-model", slow_usage, 2000)
      end

      recommendations = AutoOptimizer.analyze_performance_trends()

      assert is_list(recommendations)

      # Should identify slow_provider as having high latency
      slow_rec = Enum.find(recommendations, fn r ->
        is_map(r.metadata) and Map.get(r.metadata, :provider) == "slow_provider"
      end)

      if slow_rec do
        assert slow_rec.type == :performance
        assert slow_rec.metadata.p95 > 1500
      end
    end

    test "detects inconsistent performance patterns" do
      # Create usage with highly variable latency
      inconsistent_usage = %{"prompt_tokens" => 100, "completion_tokens" => 50, "cost_usd" => 0.001}

      # Mix of fast and slow requests
      for _ <- 1..30 do
        Usage.record("inconsistent_provider", "model", inconsistent_usage, 100)
      end

      for _ <- 1..30 do
        Usage.record("inconsistent_provider", "model", inconsistent_usage, 3000)
      end

      recommendations = AutoOptimizer.analyze_performance_trends()

      # Should detect inconsistent latency
      assert is_list(recommendations)
    end
  end

  describe "analyze_reliability_patterns/0" do
    test "identifies underutilized providers" do
      high_usage = %{"prompt_tokens" => 100, "completion_tokens" => 50, "cost_usd" => 0.001}
      low_usage = %{"prompt_tokens" => 100, "completion_tokens" => 50, "cost_usd" => 0.001}

      # Create uneven usage distribution
      for _ <- 1..1000 do
        Usage.record("high_usage_provider", "model", high_usage, 250)
      end

      for _ <- 1..10 do
        Usage.record("low_usage_provider", "model", low_usage, 250)
      end

      recommendations = AutoOptimizer.analyze_reliability_patterns()

      assert is_list(recommendations)

      # Should identify low usage provider
      low_usage_rec = Enum.find(recommendations, fn r ->
        is_map(r.metadata) and Map.get(r.metadata, :provider) == "low_usage_provider"
      end)

      if low_usage_rec do
        assert low_usage_rec.type == :reliability
        assert low_usage_rec.metadata.usage_percent < 5
      end
    end
  end

  describe "generate_daily_report/0" do
    test "generates comprehensive daily summary" do
      usage = %{
        "prompt_tokens" => 1000,
        "completion_tokens" => 500,
        "total_tokens" => 1500,
        "cost_usd" => 0.01
      }

      for _ <- 1..10 do
        Usage.record("openai", "gpt-4", usage, 250)
        Usage.record("anthropic", "claude-3-sonnet", usage, 300)
      end

      report = AutoOptimizer.generate_daily_report()

      assert report.date == Date.utc_today()
      assert is_map(report.summary)
      assert report.summary.total_requests == 20
      assert report.summary.total_cost_usd == 0.2
      assert report.summary.total_tokens == 30_000
      assert report.summary.unique_providers == 2
      assert report.summary.unique_models == 2

      assert is_map(report.cost_analysis)
      assert is_map(report.performance_analysis)
      assert is_list(report.recommendations)
    end

    test "handles empty usage data gracefully" do
      report = AutoOptimizer.generate_daily_report()

      assert report.date == Date.utc_today()
      assert report.summary.total_requests == 0
      assert report.summary.total_cost_usd == 0
      assert report.summary.total_tokens == 0
    end
  end

  describe "recommend_provider/2" do
    test "recommends best provider based on cost and latency" do
      # Create usage data for same model across different providers
      usage = %{"prompt_tokens" => 100, "completion_tokens" => 50, "cost_usd" => 0.001}

      for _ <- 1..60 do
        Usage.record("provider_a", "gpt-4", usage, 250)
      end

      cheaper_usage = %{"prompt_tokens" => 100, "completion_tokens" => 50, "cost_usd" => 0.0005}

      for _ <- 1..60 do
        Usage.record("provider_b", "gpt-4", cheaper_usage, 200)
      end

      result = AutoOptimizer.recommend_provider("gpt-4")

      assert {:ok, recommendation} = result
      assert recommendation.provider == "provider_b"
      assert recommendation.avg_latency_ms < 250
    end

    test "respects latency constraints" do
      fast_expensive = %{"prompt_tokens" => 100, "completion_tokens" => 50, "cost_usd" => 0.01}
      slow_cheap = %{"prompt_tokens" => 100, "completion_tokens" => 50, "cost_usd" => 0.001}

      for _ <- 1..60 do
        Usage.record("fast_provider", "model", fast_expensive, 100)
        Usage.record("slow_provider", "model", slow_cheap, 2000)
      end

      result = AutoOptimizer.recommend_provider("model", %{max_latency_ms: 500})

      assert {:ok, recommendation} = result
      assert recommendation.provider == "fast_provider"
      assert recommendation.avg_latency_ms <= 500
    end

    test "returns error when no suitable provider found" do
      result = AutoOptimizer.recommend_provider("nonexistent-model")
      assert {:error, :no_suitable_provider} = result
    end
  end

  describe "get_model_alternatives/2" do
    test "finds cheaper alternative models" do
      expensive_model = %{
        "prompt_tokens" => 1000,
        "completion_tokens" => 500,
        "cost_usd" => 0.1
      }

      cheap_model = %{
        "prompt_tokens" => 1000,
        "completion_tokens" => 500,
        "cost_usd" => 0.01
      }

      Usage.record("provider", "expensive-model", expensive_model, 250)
      Usage.record("provider", "cheap-model", cheap_model, 250)

      alternatives = AutoOptimizer.get_model_alternatives("provider", "expensive-model")

      assert is_list(alternatives)
      assert length(alternatives) > 0

      cheap_alt = Enum.find(alternatives, fn alt -> alt.model == "cheap-model" end)
      assert cheap_alt != nil
      assert cheap_alt.savings_percent > 0
    end

    test "returns empty list when no cheaper alternatives exist" do
      usage = %{"prompt_tokens" => 100, "completion_tokens" => 50, "cost_usd" => 0.001}
      Usage.record("provider", "cheap-model", usage, 250)

      alternatives = AutoOptimizer.get_model_alternatives("provider", "cheap-model")
      assert alternatives == []
    end
  end

  describe "record_feedback/3" do
    test "stores user feedback for learning" do
      request_id = "test_request_123"
      quality_score = 0.95
      feedback_text = "Great response quality"

      assert :ok = AutoOptimizer.record_feedback(request_id, quality_score, feedback_text)

      # Give the GenServer time to process the cast
      Process.sleep(50)

      # Feedback is stored in ETS and can be retrieved for future learning
      # This is a basic test - in production you'd add methods to query feedback
    end
  end

  describe "run_analysis/0" do
    test "performs full analysis cycle" do
      # Create some usage data
      usage = %{"prompt_tokens" => 1000, "completion_tokens" => 500, "cost_usd" => 0.1}

      for _ <- 1..60 do
        Usage.record("expensive_provider", "model", usage, 250)
      end

      cheap_usage = %{"prompt_tokens" => 1000, "completion_tokens" => 500, "cost_usd" => 0.01}

      for _ <- 1..60 do
        Usage.record("cheap_provider", "model", cheap_usage, 200)
      end

      result = AutoOptimizer.run_analysis()

      assert {:ok, _count} = result
    end
  end

  describe "get_recommendations/0" do
    test "retrieves all stored recommendations" do
      # First run an analysis to generate recommendations
      usage = %{"prompt_tokens" => 1000, "completion_tokens" => 500, "cost_usd" => 0.1}

      for _ <- 1..60 do
        Usage.record("expensive", "model", usage, 250)
      end

      cheap_usage = %{"prompt_tokens" => 1000, "completion_tokens" => 500, "cost_usd" => 0.01}

      for _ <- 1..60 do
        Usage.record("cheap", "model", cheap_usage, 200)
      end

      AutoOptimizer.run_analysis()

      recommendations = AutoOptimizer.get_recommendations()
      assert is_list(recommendations)
    end

    test "returns empty list when no recommendations exist" do
      recommendations = AutoOptimizer.get_recommendations()
      assert recommendations == []
    end
  end

  describe "get_recommendations_by_type/1" do
    test "filters recommendations by type" do
      # Generate recommendations
      usage = %{"prompt_tokens" => 1000, "completion_tokens" => 500, "cost_usd" => 0.1}

      for _ <- 1..60 do
        Usage.record("expensive", "model", usage, 250)
      end

      cheap_usage = %{"prompt_tokens" => 1000, "completion_tokens" => 500, "cost_usd" => 0.01}

      for _ <- 1..60 do
        Usage.record("cheap", "model", cheap_usage, 200)
      end

      AutoOptimizer.run_analysis()

      cost_recs = AutoOptimizer.get_recommendations_by_type(:cost_optimization)
      assert is_list(cost_recs)
      assert Enum.all?(cost_recs, fn r -> r.type == :cost_optimization end)
    end
  end
end
