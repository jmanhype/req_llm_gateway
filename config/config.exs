import Config

# RecLLMGateway configuration
config :rec_llm_gateway,
  # Server port
  port: 4000,

  # Default provider when model is specified without prefix
  default_provider: "openai",

  # Include x_rec_llm extension in responses
  include_extensions: true,

  # Optional API key for gateway authentication
  # Set to nil to disable authentication
  # api_key: System.get_env("REC_LLM_GATEWAY_KEY"),
  api_key: nil,

  # Provider API keys
  api_keys: %{
    "openai" => System.get_env("OPENAI_API_KEY"),
    "anthropic" => System.get_env("ANTHROPIC_API_KEY")
  }

# Import environment-specific config
import_config "#{config_env()}.exs"
