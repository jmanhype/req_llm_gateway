import Config

# ReqLLMGateway configuration
config :req_llm_gateway,
  # Server port
  port: 4000,

  # Default provider when model is specified without prefix
  default_provider: "openai",

  # Include x_req_llm extension in responses
  include_extensions: true,

  # Optional API key for gateway authentication
  # Set to nil to disable authentication
  # api_key: System.get_env("REQ_LLM_GATEWAY_KEY"),
  api_key: nil,

  # Provider API keys
  api_keys: %{
    "openai" => System.get_env("OPENAI_API_KEY"),
    "anthropic" => System.get_env("ANTHROPIC_API_KEY")
  },

  # AutoOptimizer configuration
  auto_optimizer: [
    # Enable/disable AI self-improvement features
    enabled: true,

    # How often to run analysis (in seconds)
    analysis_interval: 3600,

    # Number of days to keep historical data
    keep_history_days: 30,

    # Alert threshold for cost changes (percentage)
    cost_threshold_percent: 10,

    # Alert threshold for error rate (percentage)
    error_threshold_percent: 5,

    # Minimum number of samples needed before analyzing
    min_samples_for_analysis: 50
  ]

# Import environment-specific config
import_config "#{config_env()}.exs"
