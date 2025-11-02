import Config

config :rec_llm_gateway,
  port: 4000

# Enable console telemetry reporter in development
config :rec_llm_gateway, :telemetry_reporter, :console

config :logger, level: :debug
