defmodule ReqLLMGateway.Pricing do
  @moduledoc """
  Calculates costs based on token usage and model pricing.

  Pricing is configured per model with input and output costs per million tokens.
  Prices are kept up-to-date manually or can be overridden via configuration.

  ## Configuration

      config :req_llm_gateway, :pricing, %{
        "gpt-4" => %{input: 30.0, output: 60.0},
        "gpt-4-turbo" => %{input: 10.0, output: 30.0},
        # ... more models
      }

  ## Examples

      iex> usage = %{"prompt_tokens" => 1000, "completion_tokens" => 500}
      iex> ReqLLMGateway.Pricing.calculate("gpt-4", usage)
      0.06

      iex> ReqLLMGateway.Pricing.calculate("unknown-model", %{})
      nil
  """

  # Pricing in USD per 1M tokens (as of January 2024)
  # Input cost, Output cost
  @default_pricing %{
    # OpenAI
    "gpt-4" => %{input: 30.0, output: 60.0},
    "gpt-4-turbo" => %{input: 10.0, output: 30.0},
    "gpt-4-turbo-preview" => %{input: 10.0, output: 30.0},
    "gpt-4o" => %{input: 5.0, output: 15.0},
    "gpt-4o-mini" => %{input: 0.15, output: 0.6},
    "gpt-3.5-turbo" => %{input: 0.5, output: 1.5},
    "gpt-3.5-turbo-16k" => %{input: 3.0, output: 4.0},

    # Anthropic
    "claude-3-opus-20240229" => %{input: 15.0, output: 75.0},
    "claude-3-sonnet-20240229" => %{input: 3.0, output: 15.0},
    "claude-3-haiku-20240307" => %{input: 0.25, output: 1.25},
    "claude-3-5-sonnet-20241022" => %{input: 3.0, output: 15.0},
    "claude-3-5-sonnet-20240620" => %{input: 3.0, output: 15.0},

    # Generic fallbacks (for testing)
    "claude-3-opus" => %{input: 15.0, output: 75.0},
    "claude-3-sonnet" => %{input: 3.0, output: 15.0},
    "claude-3-haiku" => %{input: 0.25, output: 1.25}
  }

  @doc """
  Calculates the cost in USD for the given model and token usage.

  Returns `nil` if the model pricing is not found or if token counts are invalid.
  """
  @spec calculate(String.t(), map()) :: float() | nil
  def calculate(model, usage) when is_map(usage) do
    pricing = get_pricing()

    with %{input: input_price, output: output_price} <- Map.get(pricing, model),
         prompt_tokens when is_integer(prompt_tokens) <- Map.get(usage, "prompt_tokens"),
         completion_tokens when is_integer(completion_tokens) <-
           Map.get(usage, "completion_tokens") do
      input_cost = prompt_tokens / 1_000_000 * input_price
      output_cost = completion_tokens / 1_000_000 * output_price
      Float.round(input_cost + output_cost, 6)
    else
      _ -> nil
    end
  end

  def calculate(_, _), do: nil

  @doc """
  Returns the pricing table for all models.
  """
  @spec get_pricing() :: %{String.t() => %{input: float(), output: float()}}
  def get_pricing do
    Application.get_env(:req_llm_gateway, :pricing, @default_pricing)
  end

  @doc """
  Gets pricing for a specific model.

  Returns a map with :input and :output keys (prices per million tokens),
  or nil if not found.
  """
  @spec get_model_pricing(String.t()) :: %{input: float(), output: float()} | nil
  def get_model_pricing(model) do
    get_pricing()[model]
  end

  @doc """
  Sets custom pricing for a model at runtime.
  """
  @spec set_model_pricing(String.t(), float(), float()) :: :ok
  def set_model_pricing(model, input_price, output_price) do
    current = get_pricing()
    updated = Map.put(current, model, %{input: input_price, output: output_price})
    Application.put_env(:req_llm_gateway, :pricing, updated)
    :ok
  end
end
