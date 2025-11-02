defmodule RecLLMGateway.ModelParser do
  @moduledoc """
  Parses model identifiers to extract provider and model name.

  ## Format

  Models can be specified in two formats:
  - `provider:model` - Explicit provider (e.g., "openai:gpt-4", "anthropic:claude-3-sonnet")
  - `model` - Bare model name, uses default provider (e.g., "gpt-4")

  ## Examples

      iex> RecLLMGateway.ModelParser.parse("openai:gpt-4")
      {:ok, "openai", "gpt-4"}

      iex> RecLLMGateway.ModelParser.parse("anthropic:claude-3-sonnet-20240229")
      {:ok, "anthropic", "claude-3-sonnet-20240229"}

      iex> RecLLMGateway.ModelParser.parse("gpt-4")
      {:ok, "openai", "gpt-4"}

      iex> RecLLMGateway.ModelParser.parse("")
      {:error, %{type: "invalid_request_error", message: "Model cannot be empty", code: "invalid_model"}}
  """

  @default_provider Application.compile_env(:rec_llm_gateway, :default_provider, "openai")

  @doc """
  Parses a model string into provider and model components.

  Returns `{:ok, provider, model}` on success or `{:error, error_map}` on failure.
  """
  def parse(model) when is_binary(model) and byte_size(model) > 0 do
    case String.split(model, ":", parts: 2) do
      [provider, model_name] when byte_size(model_name) > 0 ->
        {:ok, provider, model_name}

      [model_name] ->
        {:ok, @default_provider, model_name}

      _ ->
        {:error,
         %{
           type: "invalid_request_error",
           message: "Invalid model format. Use 'provider:model' or 'model'",
           code: "invalid_model"
         }}
    end
  end

  def parse(_) do
    {:error,
     %{
       type: "invalid_request_error",
       message: "Model cannot be empty",
       code: "invalid_model"
     }}
  end
end
