use Mix.Config

config :service_gather,
  app_name: "service_gather",
  topic_prefix: "gather"

if Mix.env() == :test do
  import_config("test.exs")
end
