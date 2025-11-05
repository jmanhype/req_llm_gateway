defmodule ReqLLMGateway.DemoRouter do
  @moduledoc false
  use Phoenix.Router
  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView.Router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/" do
    pipe_through :browser

    live_dashboard "/dashboard",
      additional_pages: [
        req_llm: ReqLLMGateway.LiveDashboard
      ]
  end

  scope "/v1" do
    forward "/chat/completions", ReqLLMGateway.Plug
  end
end
