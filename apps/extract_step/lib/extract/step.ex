defprotocol Extract.Step do
  @spec execute(step :: t, context :: Extract.Steps.Context.t()) ::
          {:ok, Extract.Steps.Context.t()} | {:error, term}
  def execute(step, context)
end
