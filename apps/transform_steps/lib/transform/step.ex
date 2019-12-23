defprotocol Transform.Step do
  @spec execute(step :: t, context :: Transform.Steps.Context.t()) ::
          {:ok, Transform.Steps.Context.t()} | {:error, term}
  def execute(step, context)
end
