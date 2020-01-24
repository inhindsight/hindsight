use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :service_acquire, AcquireWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :service_acquire, AcquireWeb.V2.DataController,
  presto_client: Acquire.Presto.Mock
