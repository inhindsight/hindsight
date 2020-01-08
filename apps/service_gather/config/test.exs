use Mix.Config

config :service_gather,
  brook: [
    driver: [
      module: Brook.Driver.Test,
      init_arg: []
    ],
    handlers: [Gather.Event.Handler],
    storage: [
      module: Brook.Storage.Ets,
      init_arg: []
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

config :service_gather, Gather.Writer,
  writer: WriterMock,
  dlq: DlqMock

config :service_gather, Gather.Extraction,
  writer: Gather.WriterMock,
  chunk_size: 10,
  max_tries: 3
