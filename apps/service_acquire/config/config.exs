# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :service_acquire,
  namespace: Acquire

# Configures the endpoint
config :service_acquire, AcquireWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "LjlJ8ZSWimvBxTu6ZNbtsJbiN6QmWi6Bn+bKQaLP7OqxMnDjar1U49y0sLi4ukge",
  render_errors: [view: AcquireWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Acquire.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
