defmodule RecLLMGateway.LLMClient do
  @moduledoc """
  Behaviour and implementation for LLM API clients using ReqLLM.

  This module provides a thin wrapper around the ReqLLM library, which supports
  45+ LLM providers including OpenAI, Anthropic, Google, AWS Bedrock, and more.

  ## Configuration

  ReqLLM automatically picks up API keys from environment variables or application config:

  ### Method 1: Environment Variables (Recommended)

      export OPENAI_API_KEY="sk-..."
      export ANTHROPIC_API_KEY="sk-ant-..."
      export GOOGLE_API_KEY="..."
      # ... and so on for other providers

  ### Method 2: Application Config

      config :req_llm,
        openai_api_key: System.get_env("OPENAI_API_KEY"),
        anthropic_api_key: System.get_env("ANTHROPIC_API_KEY"),
        google_api_key: System.get_env("GOOGLE_API_KEY")

  ## Supported Providers

  ReqLLM supports 45+ providers out of the box:

  - **OpenAI**: gpt-4, gpt-3.5-turbo, etc.
  - **Anthropic**: claude-3-opus, claude-3-sonnet, claude-3-haiku
  - **Google**: gemini-pro, gemini-1.5-pro, gemini-ultra
  - **AWS Bedrock**: Various models via AWS
  - **Groq**: llama3-70b, mixtral-8x7b
  - **xAI**: grok-beta
  - **Cerebras**: llama3.1-8b, llama3.1-70b
  - **OpenRouter**: Unified access to multiple providers
  - And 35+ more!

  ## Usage

  The module uses ReqLLM's `provider:model` syntax:

      RecLLMGateway.LLMClient.chat_completion("openai", "gpt-4", request)
      RecLLMGateway.LLMClient.chat_completion("anthropic", "claude-3-opus-20240229", request)
      RecLLMGateway.LLMClient.chat_completion("google", "gemini-pro", request)

  ## Features

  - **665+ models** in the ReqLLM registry
  - **Automatic cost calculation** for all models
  - **Token counting** and usage tracking
  - **HTTP/2 streaming** support
  - **Robust error handling**
  - **Model metadata** and validation

  ## Testing

  In tests, this behaviour can be mocked using Mox for deterministic testing.
  """

  require Logger

  @callback chat_completion(provider :: String.t(), model :: String.t(), request :: map()) ::
              {:ok, map()} | {:error, map()}

  @behaviour __MODULE__

  @impl true
  def chat_completion(provider, model, request) do
    # Build the provider:model identifier that ReqLLM expects
    model_identifier = "#{provider}:#{model}"

    # Extract messages and options from the request
    messages = Map.get(request, "messages", [])

    # Build options for ReqLLM
    opts = build_options(request)

    Logger.debug("Making LLM request to #{model_identifier}")
    Logger.debug("Messages: #{inspect(messages)}")
    Logger.debug("Options: #{inspect(opts)}")

    case ReqLLM.generate_text(model_identifier, messages, opts) do
      {:ok, response} ->
        # Transform ReqLLM response to OpenAI-compatible format
        openai_response = transform_to_openai_format(response, model)
        Logger.debug("LLM response: #{inspect(openai_response)}")
        {:ok, openai_response}

      {:error, reason} = error ->
        Logger.error("LLM request failed: #{inspect(reason)}")
        # Transform error to OpenAI-compatible format
        {:error, transform_error(reason)}
    end
  rescue
    exception ->
      Logger.error("Exception in LLM request: #{inspect(exception)}")
      {:error, %{
        type: "api_error",
        message: "Internal error: #{Exception.message(exception)}"
      }}
  end

  # Build options for ReqLLM from OpenAI-style request
  defp build_options(request) do
    opts = []

    opts = maybe_add_option(opts, :temperature, request["temperature"])
    opts = maybe_add_option(opts, :max_tokens, request["max_tokens"])
    opts = maybe_add_option(opts, :top_p, request["top_p"])
    opts = maybe_add_option(opts, :frequency_penalty, request["frequency_penalty"])
    opts = maybe_add_option(opts, :presence_penalty, request["presence_penalty"])
    opts = maybe_add_option(opts, :stop, request["stop"])
    opts = maybe_add_option(opts, :stream, request["stream"])
    opts = maybe_add_option(opts, :user, request["user"])

    # Add any additional parameters that weren't explicitly handled
    custom_params = Map.drop(request, [
      "messages", "model",
      "temperature", "max_tokens", "top_p",
      "frequency_penalty", "presence_penalty",
      "stop", "stream", "user"
    ])

    if map_size(custom_params) > 0 do
      Keyword.merge(opts, Map.to_list(custom_params))
    else
      opts
    end
  end

  defp maybe_add_option(opts, _key, nil), do: opts
  defp maybe_add_option(opts, key, value), do: Keyword.put(opts, key, value)

  # Transform ReqLLM response to OpenAI-compatible format
  defp transform_to_openai_format(response, model) do
    # ReqLLM returns responses in different formats depending on the provider
    # We need to normalize to OpenAI's format
    case response do
      # If ReqLLM already returns OpenAI format (for OpenAI provider)
      %{"choices" => _choices, "usage" => _usage} = openai_format ->
        openai_format

      # If it's a direct text response, wrap it in OpenAI format
      %{"text" => text} ->
        %{
          "id" => generate_id(),
          "object" => "chat.completion",
          "created" => System.system_time(:second),
          "model" => model,
          "choices" => [
            %{
              "index" => 0,
              "message" => %{
                "role" => "assistant",
                "content" => text
              },
              "finish_reason" => "stop"
            }
          ],
          "usage" => Map.get(response, "usage", %{
            "prompt_tokens" => 0,
            "completion_tokens" => 0,
            "total_tokens" => 0
          })
        }

      # If response has content field (e.g., from Anthropic)
      %{"content" => content} = resp ->
        text_content = extract_text_content(content)
        usage = Map.get(resp, "usage", %{})

        %{
          "id" => Map.get(resp, "id", generate_id()),
          "object" => "chat.completion",
          "created" => System.system_time(:second),
          "model" => model,
          "choices" => [
            %{
              "index" => 0,
              "message" => %{
                "role" => "assistant",
                "content" => text_content
              },
              "finish_reason" => map_finish_reason(Map.get(resp, "stop_reason", "stop"))
            }
          ],
          "usage" => %{
            "prompt_tokens" => Map.get(usage, "input_tokens", 0),
            "completion_tokens" => Map.get(usage, "output_tokens", 0),
            "total_tokens" =>
              Map.get(usage, "input_tokens", 0) + Map.get(usage, "output_tokens", 0)
          }
        }

      # Fallback for unexpected formats
      other ->
        Logger.warning("Unexpected response format from ReqLLM: #{inspect(other)}")
        %{
          "id" => generate_id(),
          "object" => "chat.completion",
          "created" => System.system_time(:second),
          "model" => model,
          "choices" => [
            %{
              "index" => 0,
              "message" => %{
                "role" => "assistant",
                "content" => inspect(other)
              },
              "finish_reason" => "stop"
            }
          ],
          "usage" => %{
            "prompt_tokens" => 0,
            "completion_tokens" => 0,
            "total_tokens" => 0
          }
        }
    end
  end

  # Extract text content from various content formats
  defp extract_text_content(content) when is_binary(content), do: content
  defp extract_text_content([%{"text" => text} | _]), do: text
  defp extract_text_content([%{"type" => "text", "text" => text} | _]), do: text
  defp extract_text_content(content) when is_list(content) do
    content
    |> Enum.map(fn
      %{"text" => text} -> text
      %{"type" => "text", "text" => text} -> text
      _ -> ""
    end)
    |> Enum.join("")
  end
  defp extract_text_content(_), do: ""

  # Map various stop reasons to OpenAI's finish_reason values
  defp map_finish_reason("end_turn"), do: "stop"
  defp map_finish_reason("max_tokens"), do: "length"
  defp map_finish_reason("stop_sequence"), do: "stop"
  defp map_finish_reason("stop"), do: "stop"
  defp map_finish_reason("length"), do: "length"
  defp map_finish_reason(_), do: "stop"

  # Transform ReqLLM errors to OpenAI-compatible format
  defp transform_error(reason) when is_binary(reason) do
    %{type: "api_error", message: reason}
  end

  defp transform_error(%{message: message}) do
    %{type: "api_error", message: message}
  end

  defp transform_error(reason) do
    %{type: "api_error", message: inspect(reason)}
  end

  # Generate a unique ID for responses
  defp generate_id do
    "chatcmpl-" <> Base.encode16(:crypto.strong_rand_bytes(12), case: :lower)
  end
end
