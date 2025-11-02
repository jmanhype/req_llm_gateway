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
    # Validate request inputs
    with :ok <- validate_request(request) do
      perform_chat_completion(provider, model, request)
    end
  rescue
    exception ->
      Logger.error("Exception in LLM request for #{provider}:#{model}",
        error: Exception.message(exception),
        provider: provider,
        model: model
      )
      {:error, %{
        type: "api_error",
        message: "Internal error: #{Exception.message(exception)}"
      }}
  end

  # Validate request inputs before processing
  defp validate_request(request) do
    cond do
      not is_map(request) ->
        {:error, %{type: "invalid_request_error", message: "Request must be a map"}}

      not Map.has_key?(request, "messages") ->
        {:error, %{type: "invalid_request_error", message: "Missing required field: messages"}}

      not is_list(request["messages"]) or request["messages"] == [] ->
        {:error, %{type: "invalid_request_error", message: "Messages must be a non-empty list"}}

      not valid_messages?(request["messages"]) ->
        {:error, %{type: "invalid_request_error", message: "Invalid message format"}}

      true ->
        :ok
    end
  end

  # Validate that all messages have required fields
  defp valid_messages?(messages) do
    Enum.all?(messages, fn msg ->
      is_map(msg) and Map.has_key?(msg, "role") and Map.has_key?(msg, "content")
    end)
  end

  defp perform_chat_completion(provider, model, request) do
    # Build the provider:model identifier that ReqLLM expects
    model_identifier = "#{provider}:#{model}"

    # Extract messages and options from the request
    messages = Map.get(request, "messages", [])

    # Build options for ReqLLM
    opts = build_options(request)

    # Log request without sensitive data
    Logger.info("Making LLM request",
      provider: provider,
      model: model,
      message_count: length(messages),
      has_options: opts != []
    )

    case ReqLLM.generate_text(model_identifier, messages, opts) do
      {:ok, response} ->
        # Transform ReqLLM response to OpenAI-compatible format
        openai_response = transform_to_openai_format(response, model, provider)

        Logger.info("LLM request completed successfully",
          provider: provider,
          model: model,
          tokens: get_in(openai_response, ["usage", "total_tokens"])
        )

        {:ok, openai_response}

      {:error, reason} ->
        Logger.error("LLM request failed",
          provider: provider,
          model: model,
          error_type: error_type(reason)
        )
        # Transform error to OpenAI-compatible format
        {:error, transform_error(reason, provider, model)}
    end
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

    # Fix: Convert string keys to atoms for custom parameters
    # Use a safer approach that doesn't drop all params on error
    if map_size(custom_params) > 0 do
      custom_opts =
        custom_params
        |> Enum.reduce([], fn {key, value}, acc ->
          # Skip nil values
          if is_nil(value) do
            acc
          else
            # Safely convert string keys to atoms
            case safe_to_atom(key) do
              {:ok, atom_key} -> [{atom_key, value} | acc]
              :error ->
                Logger.warn("Skipping custom parameter with invalid key: #{inspect(key)}")
                acc
            end
          end
        end)

      Keyword.merge(opts, custom_opts)
    else
      opts
    end
  end

  # Safely convert string to existing atom, or create new atom if reasonable
  defp safe_to_atom(key) when is_atom(key), do: {:ok, key}
  defp safe_to_atom(key) when is_binary(key) do
    # Try existing atom first
    try do
      {:ok, String.to_existing_atom(key)}
    rescue
      ArgumentError ->
        # Only create new atoms for reasonable key names (alphanumeric + underscore)
        if String.match?(key, ~r/^[a-z_][a-z0-9_]*$/i) and byte_size(key) < 100 do
          {:ok, String.to_atom(key)}
        else
          :error
        end
    end
  end
  defp safe_to_atom(_), do: :error

  defp maybe_add_option(opts, _key, nil), do: opts
  defp maybe_add_option(opts, key, value), do: Keyword.put(opts, key, value)

  # Transform ReqLLM response to OpenAI-compatible format
  # Enhanced to handle more provider formats explicitly
  defp transform_to_openai_format(response, model, provider) do
    case response do
      # If ReqLLM already returns OpenAI format (for OpenAI provider)
      %{"choices" => choices, "usage" => usage} = openai_format
          when is_list(choices) and is_map(usage) ->
        openai_format

      # Handle Anthropic-style responses (content field with structured data)
      %{"content" => content, "id" => id} = resp when is_list(content) or is_binary(content) ->
        transform_anthropic_response(resp, model)

      # Handle Google Gemini-style responses
      %{"candidates" => candidates} = resp when is_list(candidates) ->
        transform_google_response(resp, model)

      # Handle responses with a direct message field
      %{"message" => %{"content" => content}} = resp ->
        transform_message_response(resp, model)

      # Handle simple text response (some providers return this)
      %{"text" => text} when is_binary(text) ->
        transform_text_response(text, response, model)

      # Handle completion field (used by some providers)
      %{"completion" => completion} when is_binary(completion) ->
        transform_text_response(completion, response, model)

      # Fallback: Try to extract any text-like field
      other ->
        Logger.warn("Unexpected response format from #{provider}",
          provider: provider,
          model: model,
          response_keys: Map.keys(other)
        )
        transform_fallback_response(other, model)
    end
  end

  # Transform Anthropic-style response
  defp transform_anthropic_response(resp, model) do
    text_content = extract_text_content(resp["content"])
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
  end

  # Transform Google Gemini-style response
  defp transform_google_response(resp, model) do
    candidates = Map.get(resp, "candidates", [])
    first_candidate = List.first(candidates) || %{}

    content =
      first_candidate
      |> get_in(["content", "parts"])
      |> extract_text_content()

    usage_metadata = Map.get(resp, "usageMetadata", %{})

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
            "content" => content
          },
          "finish_reason" => map_finish_reason(get_in(first_candidate, ["finishReason"]))
        }
      ],
      "usage" => %{
        "prompt_tokens" => Map.get(usage_metadata, "promptTokenCount", 0),
        "completion_tokens" => Map.get(usage_metadata, "candidatesTokenCount", 0),
        "total_tokens" => Map.get(usage_metadata, "totalTokenCount", 0)
      }
    }
  end

  # Transform message-style response
  defp transform_message_response(resp, model) do
    content = get_in(resp, ["message", "content"]) || ""

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
            "content" => content
          },
          "finish_reason" => "stop"
        }
      ],
      "usage" => extract_usage(resp)
    }
  end

  # Transform simple text response
  defp transform_text_response(text, response, model) do
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
      "usage" => extract_usage(response)
    }
  end

  # Fallback transformation for unknown formats
  defp transform_fallback_response(response, model) do
    # Try to extract any text content from the response
    content =
      cond do
        is_binary(response) -> response
        Map.has_key?(response, "output") -> to_string(response["output"])
        Map.has_key?(response, "result") -> to_string(response["result"])
        Map.has_key?(response, "response") -> to_string(response["response"])
        true -> Jason.encode!(response)
      end

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
            "content" => content
          },
          "finish_reason" => "stop"
        }
      ],
      "usage" => extract_usage(response)
    }
  end

  # Extract usage information from various response formats
  defp extract_usage(response) do
    case response do
      %{"usage" => usage} when is_map(usage) ->
        %{
          "prompt_tokens" => Map.get(usage, "prompt_tokens", 0),
          "completion_tokens" => Map.get(usage, "completion_tokens", 0),
          "total_tokens" => Map.get(usage, "total_tokens", 0)
        }
      _ ->
        %{
          "prompt_tokens" => 0,
          "completion_tokens" => 0,
          "total_tokens" => 0
        }
    end
  end

  # Extract text content from various content formats
  # Enhanced to handle non-text blocks gracefully
  defp extract_text_content(content) when is_binary(content), do: content
  defp extract_text_content([%{"text" => text} | _]), do: text
  defp extract_text_content([%{"type" => "text", "text" => text} | _]), do: text
  defp extract_text_content(content) when is_list(content) do
    {texts, unhandled} =
      content
      |> Enum.reduce({[], []}, fn item, {texts_acc, unhandled_acc} ->
        case item do
          %{"type" => "text", "text" => text} ->
            {[text | texts_acc], unhandled_acc}
          %{"text" => text} ->
            {[text | texts_acc], unhandled_acc}
          other ->
            {texts_acc, [other | unhandled_acc]}
        end
      end)

    # Log warning if we encountered non-text content blocks
    if unhandled != [] do
      Logger.warn("Encountered non-text content blocks",
        unhandled_types: Enum.map(unhandled, &Map.get(&1, "type", "unknown"))
      )
    end

    texts
    |> Enum.reverse()
    |> Enum.join("")
  end
  defp extract_text_content(_), do: ""

  # Map various stop reasons to OpenAI's finish_reason values
  defp map_finish_reason("end_turn"), do: "stop"
  defp map_finish_reason("max_tokens"), do: "length"
  defp map_finish_reason("stop_sequence"), do: "stop"
  defp map_finish_reason("stop"), do: "stop"
  defp map_finish_reason("length"), do: "length"
  defp map_finish_reason("STOP"), do: "stop"
  defp map_finish_reason("MAX_TOKENS"), do: "length"
  defp map_finish_reason(nil), do: "stop"
  defp map_finish_reason(_), do: "stop"

  # Transform ReqLLM errors to OpenAI-compatible format
  # Enhanced to preserve error types from ReqLLM.Error structs
  # Use idiomatic struct pattern matching
  defp transform_error(%ReqLLM.Error{type: type, message: message}, provider, model) do
    Logger.error("ReqLLM error",
      provider: provider,
      model: model,
      error_type: type,
      message: message
    )

    %{
      type: Atom.to_string(type),
      message: message,
      provider: provider,
      model: model
    }
  end

  defp transform_error(%{type: type, message: message}, provider, model) when is_atom(type) do
    %{
      type: Atom.to_string(type),
      message: message,
      provider: provider,
      model: model
    }
  end

  defp transform_error(%{message: message}, provider, model) do
    %{
      type: "api_error",
      message: message,
      provider: provider,
      model: model
    }
  end

  defp transform_error(reason, provider, model) when is_binary(reason) do
    %{
      type: "api_error",
      message: reason,
      provider: provider,
      model: model
    }
  end

  defp transform_error(reason, provider, model) do
    %{
      type: "api_error",
      message: "Request failed: #{inspect(reason)}",
      provider: provider,
      model: model
    }
  end

  # Helper to get error type for logging
  defp error_type(%ReqLLM.Error{type: type}), do: type
  defp error_type(%{type: type}), do: type
  defp error_type(_), do: :unknown

  # Generate a unique ID for responses
  defp generate_id do
    "chatcmpl-" <> Base.encode16(:crypto.strong_rand_bytes(12), case: :lower)
  end
end
