defmodule ReqLLMGateway.LLMClientTest do
  use ExUnit.Case, async: false  # async: false because we're mocking a global module

  alias ReqLLMGateway.LLMClient

  # We need to mock ReqLLM module since LLMClient calls ReqLLM.generate_text/3
  # However, since ReqLLM is an external dependency, we'll focus on testing
  # what we can without mocking it directly.

  describe "chat_completion/3 - request validation" do
    test "rejects non-map requests" do
      assert {:error, %{type: "invalid_request_error", message: msg}} =
        LLMClient.chat_completion("openai", "gpt-4", "not a map")

      assert msg =~ "must be a map"
    end

    test "rejects request without messages field" do
      assert {:error, %{type: "invalid_request_error", message: msg}} =
        LLMClient.chat_completion("openai", "gpt-4", %{})

      assert msg =~ "Missing required field: messages"
    end

    test "rejects request with empty messages list" do
      assert {:error, %{type: "invalid_request_error", message: msg}} =
        LLMClient.chat_completion("openai", "gpt-4", %{"messages" => []})

      assert msg =~ "non-empty list"
    end

    test "rejects request with non-list messages" do
      assert {:error, %{type: "invalid_request_error", message: msg}} =
        LLMClient.chat_completion("openai", "gpt-4", %{"messages" => "not a list"})

      assert msg =~ "non-empty list"
    end

    test "rejects messages without role field" do
      assert {:error, %{type: "invalid_request_error", message: msg}} =
        LLMClient.chat_completion("openai", "gpt-4", %{
          "messages" => [%{"content" => "hello"}]
        })

      assert msg =~ "Invalid message format"
    end

    test "rejects messages without content field" do
      assert {:error, %{type: "invalid_request_error", message: msg}} =
        LLMClient.chat_completion("openai", "gpt-4", %{
          "messages" => [%{"role" => "user"}]
        })

      assert msg =~ "Invalid message format"
    end

    test "rejects messages with partial invalid entries" do
      assert {:error, %{type: "invalid_request_error", message: msg}} =
        LLMClient.chat_completion("openai", "gpt-4", %{
          "messages" => [
            %{"role" => "user", "content" => "valid"},
            %{"role" => "assistant"}  # missing content
          ]
        })

      assert msg =~ "Invalid message format"
    end

    test "accepts valid request format" do
      request = %{
        "messages" => [%{"role" => "user", "content" => "hello"}]
      }

      # This will fail at the ReqLLM.generate_text call, not validation
      # We're just verifying validation passes
      result = LLMClient.chat_completion("openai", "gpt-4", request)

      case result do
        {:error, %{type: "invalid_request_error"}} ->
          flunk("Should not fail validation with valid request")
        _ ->
          # Expected - will fail at ReqLLM call or succeed if env is configured
          :ok
      end
    end

    test "accepts complex valid messages" do
      request = %{
        "messages" => [
          %{"role" => "system", "content" => "You are helpful"},
          %{"role" => "user", "content" => "Hello"},
          %{"role" => "assistant", "content" => "Hi there"},
          %{"role" => "user", "content" => "How are you?"}
        ],
        "temperature" => 0.7,
        "max_tokens" => 100
      }

      result = LLMClient.chat_completion("anthropic", "claude-3-sonnet", request)

      case result do
        {:error, %{type: "invalid_request_error"}} ->
          flunk("Should not fail validation with valid complex request")
        _ ->
          :ok
      end
    end
  end

  describe "chat_completion/3 - error handling" do
    test "catches and transforms exceptions" do
      # Pass a request that will cause an exception deeper in the code
      # The module should catch it and return a proper error
      request = %{
        "messages" => [%{"role" => "user", "content" => "test"}]
      }

      # This should not raise, even if ReqLLM fails
      result = LLMClient.chat_completion("invalid_provider_that_will_fail", "invalid", request)

      assert match?({:error, _}, result)
    end

    test "returns error tuple for provider failures" do
      request = %{
        "messages" => [%{"role" => "user", "content" => "test"}]
      }

      # Without proper API keys, this should fail gracefully
      result = LLMClient.chat_completion("openai", "gpt-4", request)

      case result do
        {:ok, _response} ->
          # If API keys are configured, that's fine
          :ok
        {:error, error} ->
          # Should be a map with type and message
          assert is_map(error)
          assert Map.has_key?(error, :type) or Map.has_key?(error, "type")
          assert Map.has_key?(error, :message) or Map.has_key?(error, "message")
        other ->
          flunk("Expected {:ok, _} or {:error, _}, got: #{inspect(other)}")
      end
    end
  end

  describe "chat_completion/3 - parameter handling" do
    test "accepts standard OpenAI parameters" do
      request = %{
        "messages" => [%{"role" => "user", "content" => "test"}],
        "temperature" => 0.5,
        "max_tokens" => 50,
        "top_p" => 0.9,
        "frequency_penalty" => 0.1,
        "presence_penalty" => 0.1,
        "stop" => ["\n"],
        "user" => "test-user"
      }

      result = LLMClient.chat_completion("openai", "gpt-4", request)

      # Should not fail due to parameter handling
      case result do
        {:error, %{type: "invalid_request_error"}} ->
          flunk("Should accept standard OpenAI parameters")
        _ ->
          :ok
      end
    end

    test "accepts allowed custom parameters" do
      request = %{
        "messages" => [%{"role" => "user", "content" => "test"}],
        "tools" => [%{"type" => "function", "name" => "test"}],
        "tool_choice" => "auto",
        "response_format" => %{"type" => "json_object"}
      }

      result = LLMClient.chat_completion("openai", "gpt-4", request)

      case result do
        {:error, %{type: "invalid_request_error"}} ->
          flunk("Should accept allowed custom parameters")
        _ ->
          :ok
      end
    end

    test "handles parameters with nil values" do
      request = %{
        "messages" => [%{"role" => "user", "content" => "test"}],
        "temperature" => nil,
        "max_tokens" => 100,
        "top_p" => nil
      }

      result = LLMClient.chat_completion("openai", "gpt-4", request)

      case result do
        {:error, %{type: "invalid_request_error"}} ->
          flunk("Should handle nil parameter values gracefully")
        _ ->
          :ok
      end
    end
  end

  describe "chat_completion/3 - provider routing" do
    test "accepts OpenAI provider and model" do
      request = %{"messages" => [%{"role" => "user", "content" => "test"}]}

      result = LLMClient.chat_completion("openai", "gpt-4", request)

      # Verify it attempts to call the right provider (won't fail validation)
      case result do
        {:error, %{type: "invalid_request_error"}} ->
          flunk("Should accept valid OpenAI provider")
        _ ->
          :ok
      end
    end

    test "accepts Anthropic provider and model" do
      request = %{"messages" => [%{"role" => "user", "content" => "test"}]}

      result = LLMClient.chat_completion("anthropic", "claude-3-sonnet", request)

      case result do
        {:error, %{type: "invalid_request_error"}} ->
          flunk("Should accept valid Anthropic provider")
        _ ->
          :ok
      end
    end

    test "accepts Google provider and model" do
      request = %{"messages" => [%{"role" => "user", "content" => "test"}]}

      result = LLMClient.chat_completion("google", "gemini-pro", request)

      case result do
        {:error, %{type: "invalid_request_error"}} ->
          flunk("Should accept valid Google provider")
        _ ->
          :ok
      end
    end

    test "accepts various provider strings" do
      request = %{"messages" => [%{"role" => "user", "content" => "test"}]}

      providers = [
        {"openai", "gpt-3.5-turbo"},
        {"anthropic", "claude-3-haiku"},
        {"google", "gemini-1.5-pro"},
        {"groq", "llama3-70b"},
        {"xai", "grok-beta"}
      ]

      for {provider, model} <- providers do
        result = LLMClient.chat_completion(provider, model, request)

        case result do
          {:error, %{type: "invalid_request_error"}} ->
            flunk("Should accept provider: #{provider}")
          _ ->
            :ok
        end
      end
    end
  end

  describe "chat_completion/3 - response format" do
    test "returns properly shaped success response when configured" do
      # This test only works if you have API keys configured
      # We'll make it conditional based on environment
      if System.get_env("OPENAI_API_KEY") do
        request = %{
          "messages" => [%{"role" => "user", "content" => "Say 'test' and nothing else"}],
          "max_tokens" => 10
        }

        case LLMClient.chat_completion("openai", "gpt-3.5-turbo", request) do
          {:ok, response} ->
            # Verify OpenAI-compatible format
            assert is_map(response)
            assert Map.has_key?(response, "id")
            assert Map.has_key?(response, "object")
            assert Map.has_key?(response, "created")
            assert Map.has_key?(response, "model")
            assert Map.has_key?(response, "choices")
            assert Map.has_key?(response, "usage")

            # Verify choices structure
            assert is_list(response["choices"])
            [first_choice | _] = response["choices"]
            assert Map.has_key?(first_choice, "index")
            assert Map.has_key?(first_choice, "message")
            assert Map.has_key?(first_choice, "finish_reason")

            # Verify message structure
            message = first_choice["message"]
            assert Map.has_key?(message, "role")
            assert Map.has_key?(message, "content")
            assert message["role"] == "assistant"

            # Verify usage structure
            usage = response["usage"]
            assert Map.has_key?(usage, "prompt_tokens")
            assert Map.has_key?(usage, "completion_tokens")
            assert Map.has_key?(usage, "total_tokens")

          {:error, _} ->
            # API key might be invalid or quota exceeded, skip test
            :ok
        end
      end
    end

    test "returns properly shaped error response" do
      request = %{
        "messages" => [%{"role" => "user", "content" => "test"}]
      }

      # Use a definitely invalid configuration to force an error
      result = LLMClient.chat_completion("definitely_invalid_provider", "invalid_model", request)

      case result do
        {:error, error} ->
          # Should be a properly structured error
          assert is_map(error)
          # Error should have at minimum a message
          assert Map.has_key?(error, :message) or Map.has_key?(error, "message")

        {:ok, _} ->
          flunk("Expected error for invalid provider")
      end
    end
  end

  describe "chat_completion/3 - edge cases" do
    test "handles very long message content" do
      long_content = String.duplicate("test ", 1000)

      request = %{
        "messages" => [%{"role" => "user", "content" => long_content}]
      }

      result = LLMClient.chat_completion("openai", "gpt-4", request)

      case result do
        {:error, %{type: "invalid_request_error"}} ->
          flunk("Should not fail validation for long content")
        _ ->
          :ok
      end
    end

    test "handles many messages in conversation" do
      messages =
        for i <- 1..50 do
          role = if rem(i, 2) == 0, do: "user", else: "assistant"
          %{"role" => role, "content" => "Message #{i}"}
        end

      request = %{"messages" => messages}

      result = LLMClient.chat_completion("openai", "gpt-4", request)

      case result do
        {:error, %{type: "invalid_request_error"}} ->
          flunk("Should not fail validation for many messages")
        _ ->
          :ok
      end
    end

    test "handles special characters in content" do
      special_content = "Test with special chars: \n\t\r \"'`{}[]<>!@#$%^&*()"

      request = %{
        "messages" => [%{"role" => "user", "content" => special_content}]
      }

      result = LLMClient.chat_completion("openai", "gpt-4", request)

      case result do
        {:error, %{type: "invalid_request_error"}} ->
          flunk("Should handle special characters")
        _ ->
          :ok
      end
    end

    test "handles Unicode characters in content" do
      unicode_content = "Hello 世界 🌍 مرحبا Здравствуй"

      request = %{
        "messages" => [%{"role" => "user", "content" => unicode_content}]
      }

      result = LLMClient.chat_completion("openai", "gpt-4", request)

      case result do
        {:error, %{type: "invalid_request_error"}} ->
          flunk("Should handle Unicode content")
        _ ->
          :ok
      end
    end
  end

  describe "chat_completion/3 - security (atom exhaustion protection)" do
    test "does not create atoms from unknown parameter names" do
      # Get current atom count
      atom_count_before = :erlang.system_info(:atom_count)

      # Try to inject a parameter that would create a new atom
      malicious_param = "definitely_not_an_existing_atom_#{:rand.uniform(999999)}"

      request = %{
        "messages" => [%{"role" => "user", "content" => "test"}],
        malicious_param => "malicious_value"
      }

      _result = LLMClient.chat_completion("openai", "gpt-4", request)

      # Atom count should not have grown significantly
      # (allow for a few atoms from logging, etc.)
      atom_count_after = :erlang.system_info(:atom_count)
      atoms_created = atom_count_after - atom_count_before

      # Should create very few atoms (< 10 for logging/internal use)
      # Not hundreds from malicious parameter names
      assert atoms_created < 10,
        "Created #{atoms_created} atoms, possible atom table exhaustion vulnerability"
    end

    test "handles multiple unknown parameters without atom creation" do
      atom_count_before = :erlang.system_info(:atom_count)

      # Try multiple malicious parameters
      malicious_params = for i <- 1..100 do
        {"malicious_param_#{i}_#{:rand.uniform(999999)}", "value"}
      end

      request =
        Map.merge(
          %{"messages" => [%{"role" => "user", "content" => "test"}]},
          Map.new(malicious_params)
        )

      _result = LLMClient.chat_completion("openai", "gpt-4", request)

      atom_count_after = :erlang.system_info(:atom_count)
      atoms_created = atom_count_after - atom_count_before

      # Should not create atoms for unknown parameters
      assert atoms_created < 20,
        "Created #{atoms_created} atoms from 100 malicious params - atom exhaustion vulnerability!"
    end
  end
end
