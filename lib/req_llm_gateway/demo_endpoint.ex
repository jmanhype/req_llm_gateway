defmodule ReqLLMGateway.DemoEndpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :req_llm_gateway

  @session_options [
    store: :cookie,
    key: "_req_llm_gateway_key",
    signing_salt: "demo_salt_12345678"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  plug Plug.Static,
    at: "/",
    from: :phoenix_live_dashboard,
    only: ~w(css fonts images js)

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  plug ReqLLMGateway.DemoRouter
end
