# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :exalted,
  ecto_repos: [Exalted.Repo]

# Configures the endpoint
config :exalted, ExaltedWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "GoUV6fSh++aQwnA4ECxM8kTMmsbdDRqO6N2p41UUTpAfi982eXSl2I5WvKL1Hc/s",
  render_errors: [view: ExaltedWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Exalted.PubSub,
  live_view: [signing_salt: "EWJirAbu"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
