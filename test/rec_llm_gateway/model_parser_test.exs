defmodule RecLLMGateway.ModelParserTest do
  use ExUnit.Case, async: true

  alias RecLLMGateway.ModelParser

  describe "parse/1" do
    test "parses provider:model format" do
      assert {:ok, "openai", "gpt-4"} = ModelParser.parse("openai:gpt-4")
      assert {:ok, "anthropic", "claude-3-sonnet"} = ModelParser.parse("anthropic:claude-3-sonnet")

      assert {:ok, "anthropic", "claude-3-sonnet-20240229"} =
               ModelParser.parse("anthropic:claude-3-sonnet-20240229")
    end

    test "uses default provider for bare model" do
      assert {:ok, "openai", "gpt-4"} = ModelParser.parse("gpt-4")
      assert {:ok, "openai", "gpt-3.5-turbo"} = ModelParser.parse("gpt-3.5-turbo")
    end

    test "returns error for empty model" do
      assert {:error, %{type: "invalid_request_error", code: "invalid_model"}} =
               ModelParser.parse("")
    end

    test "returns error for invalid format" do
      assert {:error, %{type: "invalid_request_error"}} = ModelParser.parse("provider:")
    end

    test "returns error for non-string input" do
      assert {:error, %{type: "invalid_request_error"}} = ModelParser.parse(nil)
      assert {:error, %{type: "invalid_request_error"}} = ModelParser.parse(123)
    end
  end
end
