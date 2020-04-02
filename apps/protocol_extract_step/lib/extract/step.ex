defprotocol Extract.Step do
  @spec execute(step :: t, context :: Extract.Context.t()) ::
          {:ok, Extract.Context.t()} | {:error, term}
  def execute(step, context)
end
