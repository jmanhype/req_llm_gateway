defmodule ReqLLMGateway.Application do
  @moduledoc """
  OTP Application for ReqLLMGateway.

  This application starts core services like the Usage tracker and telemetry poller.
  The HTTP server is only started in standalone mode (when run as a Mix project),
  not when used as a library in a Phoenix app.

  ## Configuration

  Set `start_server: false` in config to disable the HTTP server:

      config :req_llm_gateway, start_server: false

  By default, the server starts on port 4000 in standalone mode.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = base_children() ++ server_children()

    opts = [strategy: :one_for_one, name: ReqLLMGateway.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Core services that always start
  defp base_children do
    [
      # Start the Usage ETS table
      ReqLLMGateway.Usage,

      # Start telemetry poller
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]
  end

  # Optional HTTP server (only in standalone mode)
  defp server_children do
    if Application.get_env(:req_llm_gateway, :start_server, false) do
      [
        {Plug.Cowboy,
         scheme: :http,
         plug: ReqLLMGateway.Plug,
         options: [
           port: Application.get_env(:req_llm_gateway, :port, 4000)
         ]}
      ]
    else
      []
    end
  end

  defp periodic_measurements do
    []
  end
end
