import Config

import_config Path.expand("releases.exs", __DIR__)

Path.expand("../apps/*/config/#{Mix.env()}.exs", __DIR__)
|> Path.wildcard()
|> Enum.each(&import_config/1)
