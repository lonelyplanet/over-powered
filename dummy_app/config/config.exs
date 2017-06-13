# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :dummy_app,
  ecto_repos: [DummyApp.Repo]

# Configures the endpoint
config :dummy_app, DummyApp.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "vJrlCQK6eFHA6pz9n6FKQ3b/l6EZOtLe0pmATaO+CFLEIgPEhdu/SkM60XDPVyba",
  render_errors: [view: DummyApp.ErrorView, accepts: ~w(json)],
  pubsub: [name: DummyApp.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$message\n",
  metadata: [:request_id]

config :dummy_app, :health_check,
  service_id: "dummy-app",
  repo_name: "dummy-app",
  contact_info: %{
    slack_channel: "#dummy-app",
    service_owner_slack_id: "@idiot"
  },
  dependencies: []

config :prometheus, OverPowered.Plug.Instrumenter,
  labels: [:status_code, :controller_action],
  router: DummyApp.Router,
  registry: :default

config :prometheus, OverPowered.Plug.Exporter,
  path: "/metrics",
  format: :text,
  registry: :default

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
