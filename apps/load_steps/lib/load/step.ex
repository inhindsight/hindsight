defprotocol Load.Step do
  @spec execute(step :: t, context :: Load.Steps.Context.t()) ::
          {:ok, Load.Steps.Context.t()} | {:error, term}
  def execute(step, context)
end
