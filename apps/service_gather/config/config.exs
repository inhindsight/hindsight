use Mix.Config

config :service_gather,
  app_name: "service_gather",
  topic_prefix: "gather"

if File.exists?("config/#{Mix.env()}.exs"), do: import_config("#{Mix.env()}.exs")
