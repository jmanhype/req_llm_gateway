import Config

config :req_llm_gateway,
  port: 4001,
  # Use mock client in tests
  llm_client: ReqLLMGateway.LLMClientMock,
  api_keys: %{
    "openai" => "test-key",
    "anthropic" => "test-key"
  }

config :logger, level: :warning
