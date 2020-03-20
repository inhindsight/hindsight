use Mix.Config

config :service_define, DefineWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/parcel-bundler/bin/cli.js",
      "watch",
      "src/index.html",
      "--out-dir",
      "../priv/static/",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

config :service_define, DefineWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/define_web/(live|views)/.*(ex)$",
      ~r"lib/define_web/templates/.*(eex)$"
    ]
  ]

config :logger, :console, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
