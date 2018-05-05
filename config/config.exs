# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :what_if,
  ecto_repos: [WhatIf.Repo]

# Configures the endpoint
config :what_if, WhatIf.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "WLKAhIh9EPQQgzlJSMY6FdarRGmInlszL04S3cep26JzZZ0Ui9iiN+3iV07qODlp",
  render_errors: [view: WhatIf.ErrorView, accepts: ~w(html json)],
  pubsub: [name: WhatIf.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
