defmodule RecLLMGateway.ConnCase do
  @moduledoc """
  Test helpers for Plug connections.

  Use this in your tests like:

      use RecLLMGateway.ConnCase

  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import RecLLMGateway.ConnCase

      alias Plug.Conn
    end
  end

  @doc """
  Creates a test connection.
  """
  def conn(method, path, params_or_body \\ nil) do
    opts = [method: method, request_path: path]

    conn =
      opts
      |> Keyword.put(:host, "localhost")
      |> Plug.Adapters.Test.Conn.conn(params_or_body)

    %{conn | secret_key_base: String.duplicate("a", 64)}
  end
end
