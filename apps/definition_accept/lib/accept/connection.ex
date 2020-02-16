defprotocol Accept.Connection do
  @type connection_opts :: [
          writer: function,
          batch_size: non_neg_integer,
          timeout: non_neg_integer
        ]

  @spec connect(accept :: t, connection_opts) :: {module, keyword}
  def connect(accept, options)
end
