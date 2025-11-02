defmodule RecLLMGateway.Mocks do
  @moduledoc """
  Mock definitions for testing.
  """

  @doc """
  Returns a mock successful OpenAI chat completion response.
  """
  def mock_openai_response do
    %{
      "id" => "chatcmpl-123",
      "object" => "chat.completion",
      "created" => 1_677_858_242,
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
    }
  end

  @doc """
  Returns a mock successful Anthropic chat completion response.
  """
  def mock_anthropic_response do
    %{
      "id" => "msg_123",
      "type" => "message",
      "role" => "assistant",
      "content" => [
        %{
          "type" => "text",
          "text" => "Hello! How can I help you today?"
        }
      ],
      "model" => "claude-3-sonnet-20240229",
      "usage" => %{
        "input_tokens" => 10,
        "output_tokens" => 20
      }
    }
  end

  @doc """
  Returns a mock error response.
  """
  def mock_error_response do
    {:error, "API rate limit exceeded"}
  end
end
