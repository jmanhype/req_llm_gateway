defmodule ReqLLMGateway.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/jmanhype/recllmgateway"

  def project do
    [
      app: :req_llm_gateway,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),

      # Docs
      name: "ReqLLMGateway",
      description: "OpenAI-compatible LLM proxy with telemetry and multi-provider routing",
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs(),
      package: package(),

      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.github": :test
      ],

      # Dialyzer
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:ex_unit, :mix],
        flags: [:error_handling, :underspecs]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ReqLLMGateway.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Runtime dependencies
      {:plug, "~> 1.14"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.6"},
      {:telemetry, "~> 1.2"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:req_llm, "~> 1.0.0-rc.6"},
      {:decimal, "~> 2.1"},

      # Development dependencies
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},

      # Test dependencies
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp aliases do
    [
      test: "test --no-start",
      quality: ["format --check-formatted", "credo --strict", "dialyzer"],
      "quality.fix": ["format", "credo --strict --format=oneline"]
    ]
  end

  defp docs do
    [
      main: "ReqLLMGateway",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md": [title: "Changelog"],
        "CONTRIBUTING.md": [title: "Contributing"],
        "LICENSE": [title: "License"]
      ],
      groups_for_modules: [
        "Core Components": [
          ReqLLMGateway,
          ReqLLMGateway.Plug,
          ReqLLMGateway.LLMClient
        ],
        "Utilities": [
          ReqLLMGateway.ModelParser,
          ReqLLMGateway.Pricing
        ],
        "Observability": [
          ReqLLMGateway.Telemetry,
          ReqLLMGateway.Usage,
          ReqLLMGateway.LiveDashboard
        ],
        "Application": [
          ReqLLMGateway.Application
        ]
      ]
    ]
  end

  defp package do
    [
      name: "req_llm_gateway",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      },
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end
end
