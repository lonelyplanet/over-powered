# OverPowered

Standardized Tooling, Utilities, and Reporting for OpenPlanet Projects that use
Phoenix & Elixir.

## Utilities

### OverPowered.Pagination

A module / structure to aid in pagination queries

### OverPowered.Ids

A module to provide effecient id only pagination through a data collection.

Given a connection and specific options; this tool is designed to send a
json-api payload which has a barebones payload that can be used for sitemap
generation.

The options are:

  * repo:  The application Repo used to fetch database records
  * scope: query to page through
  * url:   A string template for each record's "self" url
  * type:  Each document's "type" field
  * extra_fields:  Sometimes you need more then the `id` field, this optional
                   option should be a list of fields as atoms to select, note
                   that `:id` is automatically included and is not needed in
                   this list

```elixir
OverPowered.Ids.fetch(conn, repo: SomeApp.Repo, scope: SomeApp.User.not_deleted,
                            url: "/users/:id", type: "user")
```

## Installation

Add `over_powered` to your list of dependencies and applications in `mix.exs`:

```elixir
def application do
  [mod: {DummyApp, []},
   applications: [:phoenix, :phoenix_pubsub, :cowboy, :logger, :gettext,
                  :phoenix_ecto, :postgrex, :over_powered]]
end

def deps do
  [{:over_powered, github: "lonelyplanet/over-powered"}]
end
```

In your Phoenix Router:

```elixir
defmodule DummyApp.Router do
  use DummyApp.Web, :router

  # Use the OverPowered.Router to provide extra pipelines of
  # :auth and :instrumentation.
  use OverPowered.Router

  # Provided by the router, this will bake in a route under
  # /health-check which will report on the status of your app
  health_check config: :dummy_app
end
```

In your Endpoint:

```elixir
defmodule DummyApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :dummy_app

  # This configures the proper logging and catches requests
  # to be instrumented when needed for Prometheus
  use OverPowered.Endpoint

  # Find and delete the following two lines of boilerplate
  # code in your Endpoint if they exist as the
  # OverPowered.Endpoint already configures these for you

  # DELETE LINE
  plug Plug.RequestId

  # DELETE LINE
  plug Plug.Logger
end
```

In your config.exs:

  Some of the following configs, such as `:logger` may already exist.  If so
  simply update them where needed.

```elixir
# Logger needs configured to only output messages
config :logger, :console,
  format: "$message\n",
  metadata: [:request_id]

# Standard health-check config, for more info see
# the lonelyplanet/health_check repo
config :dummy_app, :health_check,
  service_id: "dummy-app",
  repo_name: "dummy-app",
  contact_info: %{
    slack_channel: "#dummy-app",
    service_owner_slack_id: "@idiot"
  },
  dependencies: []

# Standard Prometheus config
config :prometheus, OverPowered.Plug.Instrumenter,
  labels: [:status_code, :controller_action],
  router: DummyApp.Router,
  registry: :default

# Standard Prometheus config
config :prometheus, OverPowered.Plug.Exporter,
  path: "/metrics",
  format: :text,
  registry: :default
```
