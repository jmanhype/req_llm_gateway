defmodule RecLLMGateway.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Usage ETS table
      RecLLMGateway.Usage,

      # Start telemetry poller
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000},

      # Start the Plug.Cowboy server
      {Plug.Cowboy,
       scheme: :http,
       plug: RecLLMGateway.Plug,
       options: [
         port: Application.get_env(:rec_llm_gateway, :port, 4000)
       ]}
    ]

    opts = [strategy: :one_for_one, name: RecLLMGateway.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp periodic_measurements do
    []
  end
end
