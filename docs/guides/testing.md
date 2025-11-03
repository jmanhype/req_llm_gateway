# Testing Strategies

Learn how to test applications using ReqLLMGateway without making real API calls.

## Configuration for Tests

In `config/test.exs`, mock the LLM client:

```elixir
import Config

config :req_llm_gateway,
  llm_client: MyApp.LLMClientMock,
  api_keys: %{
    "openai" => "test-key"
  }
```

## Using Mox

### 1. Define the Behavior

```elixir
# lib/my_app/llm_client_behaviour.ex
defmodule MyApp.LLMClientBehaviour do
  @callback call(provider :: String.t(), request :: map(), api_key :: String.t()) ::
              {:ok, map()} | {:error, term()}
end
```

### 2. Create the Mock

```elixir
# test/support/mocks.ex
Mox.defmock(MyApp.LLMClientMock, for: MyApp.LLMClientBehaviour)
```

### 3. Configure the Mock

```elixir
# config/test.exs
config :req_llm_gateway,
  llm_client: MyApp.LLMClientMock
```

### 4. Use in Tests

```elixir
defmodule MyAppTest do
  use ExUnit.Case, async: true
  import Mox

  setup :verify_on_exit!

  test "successful LLM request" do
    # Set up expectations
    expect(MyApp.LLMClientMock, :call, fn "openai", request, _api_key ->
      {:ok, %{
        "id" => "chatcmpl-123",
        "object" => "chat.completion",
        "created" => 1677858242,
        "model" => "gpt-4",
        "choices" => [
          %{
            "index" => 0,
            "message" => %{
              "role" => "assistant",
              "content" => "Hello! How can I help you today?"
            },
            "finish_reason" => "stop"
          }
        ],
        "usage" => %{
          "prompt_tokens" => 10,
          "completion_tokens" => 20,
          "total_tokens" => 30
        }
      }}
    end)

    # Make request
    conn = conn(:post, "/v1/chat/completions", %{
      "model" => "openai:gpt-4",
      "messages" => [%{"role" => "user", "content" => "Hello!"}]
    })

    conn = ReqLLMGateway.Plug.call(conn, [])

    # Assert response
    assert conn.status == 200
    response = Jason.decode!(conn.resp_body)
    assert response["choices"] |> hd() |> get_in(["message", "content"]) =~ "Hello!"
  end
end
```

## Testing with Real Endpoints

For integration tests, you can use a test provider:

```elixir
# config/test.exs
config :req_llm_gateway,
  api_keys: %{
    "test" => "test-key"
  },
  llm_client: MyApp.TestLLMClient
```

```elixir
defmodule MyApp.TestLLMClient do
  def call(_provider, request, _api_key) do
    # Return canned responses based on request
    case request["messages"] do
      [%{"content" => "error"}] ->
        {:error, "Simulated error"}

      _ ->
        {:ok, %{
          "choices" => [%{"message" => %{"content" => "Test response"}}],
          "usage" => %{"prompt_tokens" => 5, "completion_tokens" => 5, "total_tokens" => 10}
        }}
    end
  end
end
```

## Testing Telemetry

Capture telemetry events in tests:

```elixir
defmodule MyApp.TelemetryTest do
  use ExUnit.Case
  import Mox

  setup do
    # Attach test handler
    test_pid = self()

    :telemetry.attach(
      "test-handler",
      [:req_llm_gateway, :request, :stop],
      fn event, measurements, metadata, _config ->
        send(test_pid, {:telemetry, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach("test-handler")
    end)

    :ok
  end

  test "emits telemetry on successful request" do
    # Make request...

    # Assert telemetry event
    assert_receive {:telemetry, [:req_llm_gateway, :request, :stop], measurements, metadata}
    assert measurements.duration > 0
    assert measurements.total_tokens == 30
    assert metadata.provider == "openai"
  end
end
```

## Testing Usage Tracking

```elixir
test "tracks usage statistics" do
  # Clear stats
  ReqLLMGateway.Usage.clear()

  # Make request...

  # Check stats
  stats = ReqLLMGateway.Usage.get_all()
  assert length(stats) == 1

  stat = hd(stats)
  assert stat.provider == "openai"
  assert stat.model == "gpt-4"
  assert stat.calls == 1
  assert stat.total_tokens == 30
end
```

## Testing Error Handling

```elixir
test "handles provider errors gracefully" do
  expect(MyApp.LLMClientMock, :call, fn _, _, _ ->
    {:error, "API rate limit exceeded"}
  end)

  conn = conn(:post, "/v1/chat/completions", %{
    "model" => "openai:gpt-4",
    "messages" => [%{"role" => "user", "content" => "Hello!"}]
  })

  conn = ReqLLMGateway.Plug.call(conn, [])

  assert conn.status == 500
  response = Jason.decode!(conn.resp_body)
  assert response["error"]["message"] =~ "API rate limit exceeded"
end
```

## Testing with ExVCR

Record real API responses for playback in tests:

```elixir
# mix.exs
{:exvcr, "~> 0.15", only: :test}
```

```elixir
defmodule MyApp.IntegrationTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  test "real OpenAI integration" do
    use_cassette "openai_chat_completion" do
      # This will make a real request once, then replay from cassette
      conn = conn(:post, "/v1/chat/completions", %{
        "model" => "openai:gpt-4",
        "messages" => [%{"role" => "user", "content" => "Say hello"}]
      })

      conn = ReqLLMGateway.Plug.call(conn, [])

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)
      assert response["choices"] |> hd() |> get_in(["message", "content"])
    end
  end
end
```

## Best Practices

1. **Use mocks for unit tests** - Fast, deterministic, no API costs
2. **Use ExVCR for integration tests** - Real responses, but cached
3. **Test error cases** - API failures, invalid models, missing keys
4. **Test telemetry** - Ensure observability hooks work correctly
5. **Clear usage stats** - Call `ReqLLMGateway.Usage.clear()` in setup
6. **Async tests** - Most tests can run `async: true` with proper mocking
