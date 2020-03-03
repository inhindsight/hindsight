defprotocol Accept.Connection do
  @type connection_opts :: [
          writer: function,
          batch_size: non_neg_integer,
          timeout: non_neg_integer,
          name: GenServer.name()
        ]

  @spec connect(accept :: t, connection_opts) :: {module, atom, keyword}
  def connect(accept, options)
end
