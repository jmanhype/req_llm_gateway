defmodule RecLLMGateway.LLMClient do
  @moduledoc """
  Thin wrapper around ReqLLM for LLM API calls.

  This module provides an abstraction layer over ReqLLM, making it easy to
  call multiple LLM providers with a consistent interface. ReqLLM handles:
  - 45+ provider integrations
  - Automatic cost calculation
  - Model registry with 665+ models
  - Streaming support
  - Token counting

  ## Configuration

  ReqLLM supports multiple ways to configure API keys. The recommended approach
  for RecLLMGateway is to use environment variables or application config:

      # Using environment variables (recommended)
      export OPENAI_API_KEY="sk-..."
      export ANTHROPIC_API_KEY="sk-ant-..."

      # Or in config/runtime.exs
      config :req_llm,
        openai_api_key: System.get_env("OPENAI_API_KEY"),
        anthropic_api_key: System.get_env("ANTHROPIC_API_KEY")

  ## Usage

  This module is called internally by RecLLMGateway.Plug. You typically won't
  call it directly unless testing or building custom integrations.

      {:ok, response} = RecLLMGateway.LLMClient.chat_completion(
        "openai",
        "gpt-4",
        %{"messages" => [...], "temperature" => 0.7}
      )

  ## Testing

  For tests, you can mock this module using Mox:

      # config/test.exs
      config :rec_llm_gateway, :llm_client, MyApp.LLMClientMock

  See the testing guide for details.
  """

  require Logger

  @callback chat_completion(provider :: String.t(), model :: String.t(), request :: map()) ::
              {:ok, map()} | {:error, map()}

  @behaviour __MODULE__

  @doc """
  Calls an LLM provider using ReqLLM.

  ## Parameters

  - `provider` - Provider name (e.g., "openai", "anthropic", "google")
  - `model` - Model name (e.g., "gpt-4", "claude-3-sonnet-20240229")
  - `request` - OpenAI-compatible request map with:
    - `messages` - Array of message objects (required)
    - `temperature` - Sampling temperature (optional)
    - `max_tokens` - Maximum completion tokens (optional)
    - `top_p` - Nucleus sampling (optional)
    - Other OpenAI-compatible parameters

  ## Returns

  - `{:ok, response}` - OpenAI-compatible response with usage data
  - `{:error, error_map}` - Error with type, message, and optional code

  ## Examples

      iex> RecLLMGateway.LLMClient.chat_completion(
      ...>   "openai",
      ...>   "gpt-4",
      ...>   %{"messages" => [%{"role" => "user", "content" => "Hello"}]}
      ...> )
      {:ok, %{
        "id" => "chatcmpl-...",
        "choices" => [...],
        "usage" => %{"total_tokens" => 30}
      }}
  """
  @impl true
  def chat_completion(provider, model, request) do
    # Combine provider:model for ReqLLM
    model_spec = "#{provider}:#{model}"

    # Extract parameters from OpenAI request format
    messages = Map.get(request, "messages", [])

    # Build options map for ReqLLM
    opts =
      []
      |> add_if_present(:temperature, request["temperature"])
      |> add_if_present(:max_tokens, request["max_tokens"])
      |> add_if_present(:top_p, request["top_p"])
      |> add_if_present(:frequency_penalty, request["frequency_penalty"])
      |> add_if_present(:presence_penalty, request["presence_penalty"])
      |> add_if_present(:stop, request["stop"])
      |> add_if_present(:tools, request["tools"])
      |> add_if_present(:tool_choice, request["tool_choice"])

    # Call ReqLLM's generate_text function
    case ReqLLM.generate_text(model_spec, messages, opts) do
      {:ok, %{response: response_data} = _result} ->
        # ReqLLM returns structured response, transform to OpenAI format
        {:ok, format_openai_response(response_data, model)}

      {:error, reason} ->
        {:error, format_error(reason)}
    end
  rescue
    error ->
      Logger.error("LLM client error: #{inspect(error)}")

      {:error,
       %{
         type: "api_error",
         message: "Internal error: #{Exception.message(error)}",
         code: "internal_error"
       }}
  end

  # Private helpers

  defp add_if_present(opts, _key, nil), do: opts
  defp add_if_present(opts, key, value), do: Keyword.put(opts, key, value)

  # Format ReqLLM response to OpenAI-compatible format
  defp format_openai_response(response, model) do
    # ReqLLM may return different structures depending on provider
    # Normalize to OpenAI format
    case response do
      # If it's already in OpenAI format (from OpenAI provider)
      %{"choices" => _choices} = openai_response ->
        openai_response

      # Otherwise, construct OpenAI format
      %{} = response ->
        %{
          "id" => Map.get(response, "id", generate_id()),
          "object" => "chat.completion",
          "created" => System.system_time(:second),
          "model" => model,
          "choices" => format_choices(response),
          "usage" => format_usage(response)
        }
    end
  end

  defp format_choices(%{"choices" => choices}), do: choices

  defp format_choices(%{"content" => content} = response) do
    [
      %{
        "index" => 0,
        "message" => %{
          "role" => "assistant",
          "content" => content
        },
        "finish_reason" => Map.get(response, "finish_reason", "stop")
      }
    ]
  end

  defp format_choices(_), do: []

  defp format_usage(%{"usage" => usage}), do: usage

  defp format_usage(%{"input_tokens" => input, "output_tokens" => output}) do
    %{
      "prompt_tokens" => input,
      "completion_tokens" => output,
      "total_tokens" => input + output
    }
  end

  defp format_usage(_) do
    %{
      "prompt_tokens" => 0,
      "completion_tokens" => 0,
      "total_tokens" => 0
    }
  end

  # Format error to OpenAI-compatible format
  defp format_error(%{type: type, message: message} = error) when is_map(error) do
    %{
      type: to_string(type),
      message: message,
      code: Map.get(error, :code, "unknown_error")
    }
  end

  defp format_error(reason) when is_binary(reason) do
    %{
      type: "api_error",
      message: reason,
      code: "provider_error"
    }
  end

  defp format_error(reason) do
    %{
      type: "api_error",
      message: inspect(reason),
      code: "unknown_error"
    }
  end

  defp generate_id do
    "chatcmpl-" <> Base.encode16(:crypto.strong_rand_bytes(12), case: :lower)
  end
end
