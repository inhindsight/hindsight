use Mix.Config

config :definition_kafka,
  divo: [DivoKafka],
  divo_wait: [dwell: 700, max_tries: 50]
