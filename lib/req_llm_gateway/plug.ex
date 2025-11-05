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
    |> put_cors_headers()
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

    with :ok <- check_rate_limit(conn),
         :ok <- ensure_auth(conn),
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

  # --- Rate Limiting ---

  defp check_rate_limit(conn) do
    rate_limit_key = get_rate_limit_key(conn)
    {limit, time_window_ms} = get_rate_limit_config()

    case Hammer.check_rate(rate_limit_key, time_window_ms, limit) do
      {:allow, _count} ->
        :ok

      {:deny, _retry_after} ->
        {:error,
         %{
           type: "rate_limit_error",
           message: "Rate limit exceeded. Maximum #{limit} requests per #{div(time_window_ms, 1000)} seconds.",
           code: "rate_limit_exceeded"
         }}
    end
  end

  defp get_rate_limit_key(conn) do
    # Use API key if authenticated, otherwise fall back to IP address
    case get_req_header(conn, "authorization") do
      ["Bearer " <> api_key] when byte_size(api_key) > 0 ->
        "req_llm_api_key:#{api_key}"

      _ ->
        # Use remote IP for anonymous requests
        ip_address = get_remote_ip(conn)
        "req_llm_ip:#{ip_address}"
    end
  end

  defp get_remote_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [forwarded | _] ->
        # Take first IP from X-Forwarded-For header (client IP)
        forwarded
        |> String.split(",")
        |> List.first()
        |> String.trim()

      _ ->
        # Fall back to direct connection IP
        conn.remote_ip
        |> :inet.ntoa()
        |> to_string()
    end
  end

  defp get_rate_limit_config do
    # Default: 100 requests per minute
    # Can be configured via:
    #   config :req_llm_gateway, rate_limit: {200, 60_000}
    Application.get_env(:req_llm_gateway, :rate_limit, {100, 60_000})
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
    # This will call the ReqLLM adapter - for now, we'll stub it
    # In production, this would be: ReqLLM.chat_completion(provider, model, request)
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
    # Log full error details for debugging (server-side only)
    Logger.warning("Request error",
      type: type,
      message: message,
      code: Map.get(err, :code) || Map.get(err, "code"),
      error: err
    )

    # Determine HTTP status code
    status =
      case type do
        "authentication_error" -> 401
        "rate_limit_error" -> 429
        "timeout_error" -> 504
        "api_error" -> 500
        "invalid_request_error" -> 400
        _ -> 500
      end

    # Return sanitized error message to client
    sanitized_message = sanitize_error_message(type, message)

    body = %{
      "error" => %{
        "type" => type,
        "message" => sanitized_message,
        "code" => Map.get(err, :code) || Map.get(err, "code")
      }
    }

    {status, body}
  end

  # Sanitize error messages to prevent information disclosure
  # Returns generic messages for production, detailed for development
  defp sanitize_error_message(type, original_message) do
    case {type, get_error_verbosity()} do
      # Development mode - return detailed errors
      {_, :detailed} ->
        original_message

      # Production mode - return sanitized generic errors
      {"authentication_error", :sanitized} ->
        "Invalid API credentials"

      {"rate_limit_error", :sanitized} ->
        original_message  # Rate limit messages are safe (no internal details)

      {"timeout_error", :sanitized} ->
        "Request timeout. Please try again."

      {"invalid_request_error", :sanitized} ->
        # Only expose safe validation errors
        sanitize_validation_message(original_message)

      {"api_error", :sanitized} ->
        "An error occurred processing your request"

      {_, :sanitized} ->
        "An unexpected error occurred"
    end
  end

  # Sanitize validation error messages to only expose safe information
  defp sanitize_validation_message(message) do
    cond do
      message =~ ~r/messages.*(array|list)/i -> "Invalid messages format. Must be an array."
      message =~ ~r/messages.*required/i -> "Missing required field: messages"
      message =~ ~r/model.*required/i -> "Missing required field: model"
      message =~ ~r/model.*empty/i -> "Model cannot be empty"
      message =~ ~r/stream/i -> "Streaming is not supported"
      true -> "Invalid request format"
    end
  end

  defp get_error_verbosity do
    # Default to sanitized for safety
    # Set to :detailed in config/dev.exs for development
    Application.get_env(:req_llm_gateway, :error_verbosity, :sanitized)
  end

  # --- Response helpers ---

  defp send_json(conn, status, data) do
    conn
    |> put_cors_headers()
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end

  # Configure CORS headers based on application config
  # In production, set :cors_origins to a list of allowed origins
  # In development/demo, defaults to "*" for convenience
  defp put_cors_headers(conn) do
    cors_origin = get_cors_origin()
    put_resp_header(conn, "access-control-allow-origin", cors_origin)
  end

  defp get_cors_origin do
    case Application.get_env(:req_llm_gateway, :cors_origins) do
      nil ->
        # Default to wildcard for development/demo
        # WARNING: Change this in production to specific origins
        "*"

      origins when is_list(origins) and length(origins) > 0 ->
        Enum.join(origins, ", ")

      origin when is_binary(origin) ->
        origin

      _ ->
        "*"
    end
  end
end
