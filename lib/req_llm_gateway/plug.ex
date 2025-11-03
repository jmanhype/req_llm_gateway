defmodule ReqLLMGateway.Plug do
  @moduledoc """
  OpenAI-compatible gateway plug with telemetry, usage tracking, and multi-provider routing.

  ## Features
  - OpenAI-compatible API surface
  - Provider routing via provider:model format
  - Telemetry with native time units
  - Cost tracking and usage recording
  - Optional authentication
  - CORS support
  - Proper HTTP status code mapping
  """

  use Plug.Router
  require Logger

  plug(:match)
  plug(Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason)
  plug(:dispatch)

  # OPTIONS / - CORS preflight
  options "/" do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "POST, OPTIONS")
    |> put_resp_header("access-control-allow-headers", "authorization, content-type")
    |> send_resp(204, "")
  end

  # POST /v1/chat/completions - Main endpoint
  post "/v1/chat/completions" do
    handle_chat_completion(conn)
  end

  # POST / - Convenience alias
  post "/" do
    handle_chat_completion(conn)
  end

  # 404 handler
  match _ do
    send_json(conn, 404, %{
      "error" => %{
        "type" => "invalid_request_error",
        "message" => "Not found. Use POST /v1/chat/completions",
        "code" => "not_found"
      }
    })
  end

  # --- Main request handler ---

  defp handle_chat_completion(conn) do
    start_native = System.monotonic_time()

    with :ok <- ensure_auth(conn),
         {:ok, request} <- validate_request(conn.body_params),
         :ok <- reject_streaming(request),
         {:ok, provider, model} <- ReqLLMGateway.ModelParser.parse(request["model"]),
         :ok <- ReqLLMGateway.Telemetry.emit_start(provider, model),
         {:ok, resp0} <- call_llm(provider, model, request),
         response <- ensure_openai_shape(resp0),
         duration_native <- System.monotonic_time() - start_native,
         latency_ms <- System.convert_time_unit(duration_native, :native, :millisecond),
         response <- maybe_add_extensions(response, provider, latency_ms),
         :ok <- record_usage(response, provider, latency_ms) do
      ReqLLMGateway.Telemetry.emit_stop(request, response, provider, duration_native)
      send_json(conn, 200, response)
    else
      {:error, error} ->
        ReqLLMGateway.Telemetry.emit_exception(error)
        {status, body} = format_error(error)
        send_json(conn, status, body)
    end
  end

  # --- Authentication ---

  defp ensure_auth(conn) do
    case Application.get_env(:req_llm_gateway, :api_key) do
      nil ->
        :ok

      expected ->
        with ["Bearer " <> got] <- get_req_header(conn, "authorization"),
             true <- Plug.Crypto.secure_compare(got, expected) do
          :ok
        else
          _ ->
            {:error,
             %{
               type: "authentication_error",
               message: "Invalid API key",
               code: "invalid_api_key"
             }}
        end
    end
  end

  # --- Validation ---

  defp validate_request(%{"messages" => msgs, "model" => _} = req) when is_list(msgs),
    do: {:ok, req}

  defp validate_request(%{"model" => _}),
    do:
      {:error,
       %{
         type: "invalid_request_error",
         message: "Field 'messages' must be an array",
         code: "invalid_messages"
       }}

  defp validate_request(_),
    do:
      {:error,
       %{
         type: "invalid_request_error",
         message: "Missing required fields: messages, model",
         code: "missing_fields"
       }}

  defp reject_streaming(%{"stream" => true}) do
    {:error,
     %{
       type: "invalid_request_error",
       message: "Streaming is not enabled for this gateway.",
       code: "stream_not_supported"
     }}
  end

  defp reject_streaming(_), do: :ok

  # --- LLM calling ---

  defp call_llm(provider, model, request) do
    # This will call the RecLLM adapter - for now, we'll stub it
    # In production, this would be: RecLLM.chat_completion(provider, model, request)
    adapter = Application.get_env(:req_llm_gateway, :llm_client, ReqLLMGateway.LLMClient)
    adapter.chat_completion(provider, model, request)
  end

  # --- Response shaping ---

  defp ensure_openai_shape(response) do
    response
    |> Map.put_new("id", "chatcmpl-" <> Base.encode16(:crypto.strong_rand_bytes(10), case: :lower))
    |> Map.put_new("object", "chat.completion")
    |> Map.put_new("created", System.system_time(:second))
  end

  defp maybe_add_extensions(response, provider, latency_ms) do
    if Application.get_env(:req_llm_gateway, :include_extensions, true) do
      cost = ReqLLMGateway.Pricing.calculate(response["model"], response["usage"] || %{})

      Map.put(response, "x_req_llm", %{
        "provider" => provider,
        "latency_ms" => latency_ms,
        "cost_usd" => cost
      })
    else
      response
    end
  end

  defp record_usage(response, provider, latency_ms) do
    cost = get_in(response, ["x_req_llm", "cost_usd"])
    usage = Map.put(response["usage"] || %{}, "cost_usd", cost)
    ReqLLMGateway.Usage.record(provider, response["model"], usage, latency_ms)
  end

  # --- Error handling ---

  defp format_error(%{type: type, message: message} = err) do
    status =
      case type do
        "authentication_error" -> 401
        "rate_limit_error" -> 429
        "timeout_error" -> 504
        "api_error" -> 500
        "invalid_request_error" -> 400
        _ -> 500
      end

    body = %{
      "error" => %{
        "type" => type,
        "message" => message,
        "code" => Map.get(err, :code) || Map.get(err, "code")
      }
    }

    {status, body}
  end

  # --- Response helpers ---

  defp send_json(conn, status, data) do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end
end
