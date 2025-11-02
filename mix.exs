defmodule RecLLMGateway.MixProject do
  use Mix.Project

  def project do
    [
      app: :rec_llm_gateway,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {RecLLMGateway.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:plug, "~> 1.14"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.6"},
      {:telemetry, "~> 1.2"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:httpoison, "~> 2.0"},
      {:decimal, "~> 2.1"},

      # Test dependencies
      {:mox, "~> 1.0", only: :test},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end
end
