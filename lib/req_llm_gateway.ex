defmodule ReqLLMGateway do
  @moduledoc """
  ReqLLMGateway - OpenAI-compatible LLM proxy for Elixir/Phoenix applications.

  ReqLLMGateway is a production-ready library that provides an OpenAI-compatible
  endpoint with built-in telemetry, usage tracking, and multi-provider routing.

  ## Features

  - **OpenAI-compatible API** - Works with existing SDKs and tools
  - **Multi-provider routing** - Support for OpenAI, Anthropic, and more
  - **Built-in telemetry** - Comprehensive observability hooks
  - **Usage tracking** - In-memory ETS-backed statistics
  - **Cost tracking** - Automatic cost calculation per provider
  - **LiveDashboard integration** - Real-time monitoring UI

  ## Quick Start

  Add to your Phoenix router:

      # lib/my_app_web/router.ex
      scope "/v1" do
        forward "/chat/completions", ReqLLMGateway.Plug
      end

  Configure API keys:

      # config/config.exs
      config :req_llm_gateway,
        api_keys: %{
          "openai" => System.get_env("OPENAI_API_KEY"),
          "anthropic" => System.get_env("ANTHROPIC_API_KEY")
        }

  ## Usage

  Use any OpenAI-compatible client:

      curl http://localhost:4000/v1/chat/completions \\
        -H "Content-Type: application/json" \\
        -d '{
          "model": "openai:gpt-4",
          "messages": [{"role": "user", "content": "Hello!"}]
        }'

  ## Configuration

  All configuration options:

      config :req_llm_gateway,
        # Required: Provider API keys
        api_keys: %{
          "openai" => "sk-...",
          "anthropic" => "sk-ant-..."
        },
        # Optional: Default provider when no prefix specified (default: "openai")
        default_provider: "openai",
        # Optional: Include x_req_llm extension in responses (default: true)
        include_extensions: true,
        # Optional: Gateway authentication key
        api_key: System.get_env("GATEWAY_API_KEY"),
        # Optional: Custom LLM client for testing
        llm_client: ReqLLMGateway.LLMClient

  ## Architecture

  ReqLLMGateway is composed of several modules:

  - `ReqLLMGateway.Plug` - Main HTTP endpoint handler
  - `ReqLLMGateway.LLMClient` - Multi-provider LLM client
  - `ReqLLMGateway.ModelParser` - Provider:model format parser
  - `ReqLLMGateway.Pricing` - Cost calculation per provider/model
  - `ReqLLMGateway.Usage` - ETS-backed usage statistics
  - `ReqLLMGateway.Telemetry` - Telemetry event definitions
  - `ReqLLMGateway.LiveDashboard` - Phoenix LiveDashboard integration

  ## Telemetry

  ReqLLMGateway emits the following telemetry events:

  - `[:req_llm_gateway, :request, :start]` - Request initiated
  - `[:req_llm_gateway, :request, :stop]` - Request completed (includes duration, tokens, cost)
  - `[:req_llm_gateway, :request, :exception]` - Request failed

  ## Response Format

  Responses include standard OpenAI fields plus optional extensions:

      {
        "id": "chatcmpl-123",
        "object": "chat.completion",
        "created": 1677858242,
        "model": "gpt-4",
        "choices": [...],
        "usage": {
          "prompt_tokens": 10,
          "completion_tokens": 20,
          "total_tokens": 30
        },
        "x_req_llm": {
          "provider": "openai",
          "latency_ms": 342,
          "cost_usd": 0.000063
        }
      }

  ## Testing

  Mock the LLM client in tests:

      # config/test.exs
      config :req_llm_gateway,
        llm_client: MyApp.LLMClientMock

  See the test directory for examples using Mox.

  ## License

  MIT License - see LICENSE file for details.
  """

  @doc """
  Returns the current version of ReqLLMGateway.

  ## Examples

      iex> ReqLLMGateway.version()
      "0.1.0"
  """
  @spec version() :: String.t()
  def version do
    Application.spec(:req_llm_gateway, :vsn) |> to_string()
  end

  @doc """
  Returns the configured default provider.

  ## Examples

      iex> ReqLLMGateway.default_provider()
      "openai"
  """
  @spec default_provider() :: String.t()
  def default_provider do
    Application.get_env(:req_llm_gateway, :default_provider, "openai")
  end

  @doc """
  Checks if the gateway is properly configured with required API keys.

  Returns `{:ok, providers}` if at least one provider is configured,
  or `{:error, :no_api_keys}` if no providers are available.

  ## Examples

      iex> ReqLLMGateway.configured?()
      {:ok, ["openai", "anthropic"]}

      iex> ReqLLMGateway.configured?()
      {:error, :no_api_keys}
  """
  @spec configured?() :: {:ok, [String.t()]} | {:error, :no_api_keys}
  def configured? do
    case Application.get_env(:req_llm_gateway, :api_keys, %{}) do
      api_keys when map_size(api_keys) > 0 ->
        providers = api_keys |> Map.keys() |> Enum.filter(&(not is_nil(Map.get(api_keys, &1))))
        if length(providers) > 0 do
          {:ok, providers}
        else
          {:error, :no_api_keys}
        end

      _ ->
        {:error, :no_api_keys}
    end
  end
end
