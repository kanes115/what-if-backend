use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :what_if, WhatIf.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :what_if, HelloPhoenix.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "",
  database: "hello_phoenix_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
