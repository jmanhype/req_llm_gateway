defmodule ReqLLMGateway.PlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import Mox

  alias ReqLLMGateway.Plug, as: GatewayPlug

  setup :verify_on_exit!

  setup do
    # Start Usage for tests
    start_supervised!(ReqLLMGateway.Usage)
    ReqLLMGateway.Usage.clear_all()
    :ok
  end

  describe "POST /v1/chat/completions" do
    test "returns 200 with valid OpenAI response" do
      mock_response = %{
        "id" => "chatcmpl-123",
        "object" => "chat.completion",
        "created" => 1_234_567_890,
        "model" => "gpt-4",
        "choices" => [
          %{
            "index" => 0,
            "message" => %{"role" => "assistant", "content" => "Hello!"},
            "finish_reason" => "stop"
          }
        ],
        "usage" => %{
          "prompt_tokens" => 10,
          "completion_tokens" => 5,
          "total_tokens" => 15
        }
      }

      expect(ReqLLMGateway.LLMClientMock, :chat_completion, fn "openai", "gpt-4", _request ->
        {:ok, mock_response}
      end)

      request_body = %{
        "model" => "gpt-4",
        "messages" => [%{"role" => "user", "content" => "Hi"}]
      }

      conn =
        conn(:post, "/v1/chat/completions", request_body)
        |> put_req_header("content-type", "application/json")
        |> GatewayPlug.call([])

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)

      assert response["id"]
      assert response["choices"]
      assert response["usage"]
      assert response["x_req_llm"]["provider"] == "openai"
      assert response["x_req_llm"]["latency_ms"]
      assert response["x_req_llm"]["cost_usd"]
    end

    test "rejects stream=true with proper error" do
      request_body = %{
        "model" => "gpt-4",
        "messages" => [%{"role" => "user", "content" => "Hi"}],
        "stream" => true
      }

      conn =
        conn(:post, "/v1/chat/completions", request_body)
        |> put_req_header("content-type", "application/json")
        |> GatewayPlug.call([])

      assert conn.status == 400
      response = Jason.decode!(conn.resp_body)

      assert response["error"]["type"] == "invalid_request_error"
      assert response["error"]["code"] == "stream_not_supported"
    end

    test "returns 400 for missing messages" do
      request_body = %{"model" => "gpt-4"}

      conn =
        conn(:post, "/v1/chat/completions", request_body)
        |> put_req_header("content-type", "application/json")
        |> GatewayPlug.call([])

      assert conn.status == 400
      response = Jason.decode!(conn.resp_body)

      assert response["error"]["type"] == "invalid_request_error"
      assert response["error"]["code"] == "invalid_messages"
    end

    test "returns 400 for missing model" do
      request_body = %{"messages" => [%{"role" => "user", "content" => "Hi"}]}

      conn =
        conn(:post, "/v1/chat/completions", request_body)
        |> put_req_header("content-type", "application/json")
        |> GatewayPlug.call([])

      assert conn.status == 400
      response = Jason.decode!(conn.resp_body)

      assert response["error"]["type"] == "invalid_request_error"
      assert response["error"]["code"] == "missing_fields"
    end

    test "routes provider:model correctly" do
      mock_response = %{
        "id" => "msg-123",
        "model" => "claude-3-sonnet",
        "choices" => [
          %{
            "index" => 0,
            "message" => %{"role" => "assistant", "content" => "Hello!"},
            "finish_reason" => "stop"
          }
        ],
        "usage" => %{"prompt_tokens" => 10, "completion_tokens" => 5, "total_tokens" => 15}
      }

      expect(
        ReqLLMGateway.LLMClientMock,
        :chat_completion,
        fn "anthropic", "claude-3-sonnet", _request ->
          {:ok, mock_response}
        end
      )

      request_body = %{
        "model" => "anthropic:claude-3-sonnet",
        "messages" => [%{"role" => "user", "content" => "Hi"}]
      }

      conn =
        conn(:post, "/v1/chat/completions", request_body)
        |> put_req_header("content-type", "application/json")
        |> GatewayPlug.call([])

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)
      assert response["x_req_llm"]["provider"] == "anthropic"
    end
  end

  describe "OPTIONS /" do
    test "returns CORS preflight headers" do
      conn =
        conn(:options, "/")
        |> GatewayPlug.call([])

      assert conn.status == 204
      assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
      assert get_resp_header(conn, "access-control-allow-methods") == ["POST, OPTIONS"]

      assert get_resp_header(conn, "access-control-allow-headers") == [
               "authorization, content-type"
             ]
    end
  end

  describe "404 handler" do
    test "returns JSON error for unknown routes" do
      conn =
        conn(:get, "/unknown")
        |> GatewayPlug.call([])

      assert conn.status == 404
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]

      response = Jason.decode!(conn.resp_body)
      assert response["error"]["type"] == "invalid_request_error"
      assert response["error"]["code"] == "not_found"
    end
  end

  describe "error status mapping" do
    test "maps authentication_error to 401" do
      expect(ReqLLMGateway.LLMClientMock, :chat_completion, fn _, _, _ ->
        {:error, %{type: "authentication_error", message: "Invalid API key"}}
      end)

      request_body = %{
        "model" => "gpt-4",
        "messages" => [%{"role" => "user", "content" => "Hi"}]
      }

      conn =
        conn(:post, "/v1/chat/completions", request_body)
        |> put_req_header("content-type", "application/json")
        |> GatewayPlug.call([])

      assert conn.status == 401
    end

    test "maps rate_limit_error to 429" do
      expect(ReqLLMGateway.LLMClientMock, :chat_completion, fn _, _, _ ->
        {:error, %{type: "rate_limit_error", message: "Rate limit exceeded"}}
      end)

      request_body = %{
        "model" => "gpt-4",
        "messages" => [%{"role" => "user", "content" => "Hi"}]
      }

      conn =
        conn(:post, "/v1/chat/completions", request_body)
        |> put_req_header("content-type", "application/json")
        |> GatewayPlug.call([])

      assert conn.status == 429
    end

    test "maps timeout_error to 504" do
      expect(ReqLLMGateway.LLMClientMock, :chat_completion, fn _, _, _ ->
        {:error, %{type: "timeout_error", message: "Request timeout"}}
      end)

      request_body = %{
        "model" => "gpt-4",
        "messages" => [%{"role" => "user", "content" => "Hi"}]
      }

      conn =
        conn(:post, "/v1/chat/completions", request_body)
        |> put_req_header("content-type", "application/json")
        |> GatewayPlug.call([])

      assert conn.status == 504
    end

    test "maps api_error to 500" do
      expect(ReqLLMGateway.LLMClientMock, :chat_completion, fn _, _, _ ->
        {:error, %{type: "api_error", message: "Internal server error"}}
      end)

      request_body = %{
        "model" => "gpt-4",
        "messages" => [%{"role" => "user", "content" => "Hi"}]
      }

      conn =
        conn(:post, "/v1/chat/completions", request_body)
        |> put_req_header("content-type", "application/json")
        |> GatewayPlug.call([])

      assert conn.status == 500
    end
  end
end
