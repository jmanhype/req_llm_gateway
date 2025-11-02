defmodule RecLLMGateway.LLMClient do
  @moduledoc """
  Behaviour and default implementation for LLM API clients.

  This module defines the contract for calling LLM providers and provides
  a basic HTTP implementation. In tests, this can be mocked using Mox.

  ## Configuration

  Provider API keys should be configured in your application config:

      config :rec_llm_gateway, :api_keys, %{
        "openai" => System.get_env("OPENAI_API_KEY"),
        "anthropic" => System.get_env("ANTHROPIC_API_KEY")
      }
  """

  @callback chat_completion(provider :: String.t(), model :: String.t(), request :: map()) ::
              {:ok, map()} | {:error, map()}

  @behaviour __MODULE__

  @impl true
  def chat_completion(provider, model, request) do
    case provider do
      "openai" -> openai_chat_completion(model, request)
      "anthropic" -> anthropic_chat_completion(model, request)
      _ -> {:error, %{type: "api_error", message: "Unsupported provider: #{provider}"}}
    end
  end

  # OpenAI implementation
  defp openai_chat_completion(model, request) do
    url = "https://api.openai.com/v1/chat/completions"
    api_key = get_api_key("openai")

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    body =
      request
      |> Map.put("model", model)
      |> Jason.encode!()

    case HTTPoison.post(url, body, headers, timeout: 60_000, recv_timeout: 60_000) do
      {:ok, %{status_code: 200, body: response_body}} ->
        {:ok, Jason.decode!(response_body)}

      {:ok, %{status_code: status, body: response_body}} ->
        error = Jason.decode!(response_body)
        {:error, Map.get(error, "error", %{type: "api_error", message: "HTTP #{status}"})}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, %{type: "timeout_error", message: "Request failed: #{inspect(reason)}"}}
    end
  end

  # Anthropic implementation
  defp anthropic_chat_completion(model, request) do
    url = "https://api.anthropic.com/v1/messages"
    api_key = get_api_key("anthropic")

    headers = [
      {"x-api-key", api_key},
      {"anthropic-version", "2023-06-01"},
      {"Content-Type", "application/json"}
    ]

    # Transform OpenAI format to Anthropic format
    body =
      %{
        "model" => model,
        "max_tokens" => request["max_tokens"] || 1024,
        "messages" => request["messages"]
      }
      |> maybe_add("temperature", request["temperature"])
      |> maybe_add("top_p", request["top_p"])
      |> maybe_add("stop_sequences", request["stop"])
      |> Jason.encode!()

    case HTTPoison.post(url, body, headers, timeout: 60_000, recv_timeout: 60_000) do
      {:ok, %{status_code: 200, body: response_body}} ->
        anthropic_response = Jason.decode!(response_body)
        {:ok, transform_anthropic_response(anthropic_response, model)}

      {:ok, %{status_code: status, body: response_body}} ->
        error = Jason.decode!(response_body)
        {:error, Map.get(error, "error", %{type: "api_error", message: "HTTP #{status}"})}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, %{type: "timeout_error", message: "Request failed: #{inspect(reason)}"}}
    end
  end

  # Transform Anthropic response to OpenAI format
  defp transform_anthropic_response(response, model) do
    %{
      "id" => response["id"],
      "object" => "chat.completion",
      "created" => System.system_time(:second),
      "model" => model,
      "choices" => [
        %{
          "index" => 0,
          "message" => %{
            "role" => "assistant",
            "content" => get_content_text(response["content"])
          },
          "finish_reason" => map_stop_reason(response["stop_reason"])
        }
      ],
      "usage" => %{
        "prompt_tokens" => response["usage"]["input_tokens"],
        "completion_tokens" => response["usage"]["output_tokens"],
        "total_tokens" =>
          response["usage"]["input_tokens"] + response["usage"]["output_tokens"]
      }
    }
  end

  defp get_content_text([%{"text" => text} | _]), do: text
  defp get_content_text([%{"type" => "text", "text" => text} | _]), do: text
  defp get_content_text(_), do: ""

  defp map_stop_reason("end_turn"), do: "stop"
  defp map_stop_reason("max_tokens"), do: "length"
  defp map_stop_reason("stop_sequence"), do: "stop"
  defp map_stop_reason(_), do: "stop"

  defp maybe_add(map, _key, nil), do: map
  defp maybe_add(map, key, value), do: Map.put(map, key, value)

  defp get_api_key(provider) do
    api_keys = Application.get_env(:rec_llm_gateway, :api_keys, %{})
    Map.get(api_keys, provider) || raise "Missing API key for provider: #{provider}"
  end
end
