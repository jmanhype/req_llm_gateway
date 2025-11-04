# ReqLLMGateway

**OpenAI-compatible LLM proxy. Drop into Phoenix. Done.**

```elixir
# In your router.ex
forward "/v1/chat/completions", ReqLLMGateway.Plug
```

That's it. You now have a production-ready LLM gateway.

## What You Get

- ✅ **OpenAI-compatible endpoint** - Works with existing SDKs (Python, JS, curl)
- ✅ **45+ providers, 665+ models** - Powered by ReqLLM
- ✅ **Multi-provider routing** - `openai:gpt-4`, `anthropic:claude-3-sonnet`, `google:gemini-pro`
- ✅ **Built-in telemetry** - Emit events for observability
- ✅ **Usage tracking** - ETS-backed stats (no database needed)
- ✅ **Automatic cost tracking** - ReqLLM knows pricing for all models
- ✅ **LiveDashboard** - See usage stats at `/dashboard/req_llm`
- ✨ **AI Self-Improvement** - Automated optimization recommendations

## Installation

Add to `mix.exs`:

```elixir
def deps do
  [
    {:req_llm_gateway, "~> 0.1.0"}
  ]
end
```

## Quick Start

### 1. Configure API Keys

ReqLLM automatically picks up API keys from environment variables:

```bash
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
export GOOGLE_API_KEY="..."
# ... and so on for other providers
```

Or configure explicitly:

```elixir
# config/config.exs
config :req_llm,
  openai_api_key: System.get_env("OPENAI_API_KEY"),
  anthropic_api_key: System.get_env("ANTHROPIC_API_KEY"),
  google_api_key: System.get_env("GOOGLE_API_KEY")
```

### 2. Add to Router

```elixir
# lib/my_app_web/router.ex
scope "/v1" do
  forward "/chat/completions", ReqLLMGateway.Plug
end

# Add LiveDashboard pages
live_dashboard "/dashboard",
  additional_pages: [
    req_llm: ReqLLMGateway.LiveDashboard,
    optimizer: ReqLLMGateway.LiveDashboardOptimizer
  ]
```

### 3. Use It

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai:gpt-4",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Model Routing

ReqLLMGateway supports 45+ providers via ReqLLM:

**Specify provider explicitly:**
```json
{"model": "openai:gpt-4"}
{"model": "anthropic:claude-3-opus-20240229"}
{"model": "google:gemini-1.5-pro"}
{"model": "groq:llama3-70b"}
{"model": "xai:grok-beta"}
```

**Or use default provider:**
```json
{"model": "gpt-4"}  // Uses default_provider from config
```

**Supported providers include:**
- OpenAI, Anthropic, Google, AWS Bedrock
- Groq, xAI, Cerebras, OpenRouter
- And 35+ more!

## Response Format

Standard OpenAI response + optional extensions:

```json
{
  "choices": [...],
  "usage": {"prompt_tokens": 10, "completion_tokens": 20},
  "x_req_llm": {
    "provider": "openai",
    "latency_ms": 342,
    "cost_usd": 0.000063
  }
}
```

## Works With Existing Tools

**Python:**
```python
from openai import OpenAI

client = OpenAI(base_url="http://localhost:4000/v1", api_key="not-needed")
response = client.chat.completions.create(
    model="anthropic:claude-3-sonnet-20240229",
    messages=[{"role": "user", "content": "Hello!"}]
)
```

**JavaScript, Go, Ruby** - Any OpenAI-compatible SDK works.

## Configuration Options

```elixir
# ReqLLMGateway config
config :req_llm_gateway,
  # Default provider when model has no prefix (default: "openai")
  default_provider: "openai",

  # Include x_req_llm extension in responses (default: true)
  include_extensions: true,

  # Optional gateway authentication
  api_key: System.get_env("GATEWAY_API_KEY"),

  # AutoOptimizer configuration
  auto_optimizer: [
    enabled: true,                    # Enable AI self-improvement
    analysis_interval: 3600,          # Run analysis every hour (in seconds)
    keep_history_days: 30,            # Keep 30 days of data
    cost_threshold_percent: 10,       # Alert if cost changes by >10%
    error_threshold_percent: 5,       # Alert if error rate > 5%
    min_samples_for_analysis: 50      # Minimum samples before analyzing
  ]

# ReqLLM provider API keys
config :req_llm,
  openai_api_key: System.get_env("OPENAI_API_KEY"),
  anthropic_api_key: System.get_env("ANTHROPIC_API_KEY"),
  google_api_key: System.get_env("GOOGLE_API_KEY")
  # ... add keys for other providers as needed
```

## Usage Tracking

Stats are automatically tracked in ETS:

```elixir
ReqLLMGateway.Usage.get_all()
#=> [
#  %{
#    date: ~D[2024-01-15],
#    provider: "openai",
#    model: "gpt-4",
#    calls: 42,
#    total_tokens: 2140,
#    cost_usd: 0.128,
#    avg_latency_ms: 325
#  }
#]
```

Or view in LiveDashboard at `/dashboard/req_llm`.

## AI Self-Improvement Automation

ReqLLMGateway includes an intelligent AutoOptimizer that continuously analyzes your usage patterns and provides actionable recommendations to reduce costs, improve performance, and increase reliability.

### Features

**Cost Optimization**
- Identifies expensive providers and suggests cheaper alternatives
- Calculates potential savings and ROI
- Tracks cost trends over time

**Performance Analysis**
- Monitors latency across providers
- Detects performance degradation
- Identifies inconsistent response times

**Reliability Monitoring**
- Tracks usage distribution
- Identifies underutilized providers
- Detects anomalies in usage patterns

### Accessing Recommendations

**View in LiveDashboard:**
```
http://localhost:4000/dashboard/optimizer
```

**Programmatic access:**
```elixir
# Get all recommendations
ReqLLMGateway.AutoOptimizer.get_recommendations()

# Get cost optimization opportunities
ReqLLMGateway.AutoOptimizer.analyze_cost_opportunities()

# Generate daily report
ReqLLMGateway.AutoOptimizer.generate_daily_report()

# Get provider recommendation for a model
ReqLLMGateway.AutoOptimizer.recommend_provider("gpt-4", %{max_latency_ms: 500})

# Find cheaper model alternatives
ReqLLMGateway.AutoOptimizer.get_model_alternatives("openai", "gpt-4")
```

### How It Works

1. **Continuous Learning**: AutoOptimizer runs periodic analysis (configurable interval)
2. **Pattern Detection**: Analyzes usage data from the ETS-backed tracking system
3. **Smart Recommendations**: Generates prioritized suggestions based on:
   - Cost per 1K tokens across providers
   - Latency percentiles (p50, p95, p99)
   - Usage distribution and trends
4. **Actionable Insights**: Each recommendation includes:
   - Priority level (Critical, High, Medium, Low)
   - Impact estimate (cost savings, latency reduction)
   - Specific actions to take

### Configuration

```elixir
config :req_llm_gateway,
  auto_optimizer: [
    enabled: true,                    # Turn on/off auto-optimization
    analysis_interval: 3600,          # How often to analyze (seconds)
    min_samples_for_analysis: 50      # Min requests before recommendations
  ]
```

### Manual Analysis

Trigger analysis on-demand:

```elixir
ReqLLMGateway.AutoOptimizer.run_analysis()
```

## Telemetry

Emits standard telemetry events:

- `[:req_llm_gateway, :request, :start]`
- `[:req_llm_gateway, :request, :stop]` - includes tokens, latency
- `[:req_llm_gateway, :request, :exception]`

Hook into your existing observability stack.

## Testing

Mock the LLM client in tests:

```elixir
# config/test.exs
config :req_llm_gateway,
  llm_client: MyApp.LLMClientMock
```

See `test/` directory for examples.

## That's It

~500 lines of code. Zero JavaScript. No database. Just Elixir.

Add it to your Phoenix app and you have a production-ready LLM gateway with telemetry, usage tracking, and multi-provider routing.

**Heads will explode.** 🤯

## MVP Limitations

- **No streaming** - `stream: true` returns an error (coming soon)
- **No persistence** - Usage data is in-memory (restart = reset)
- **No rate limiting** - Add a reverse proxy if needed

## License

MIT
