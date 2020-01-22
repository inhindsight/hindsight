defprotocol Transform.Step do
  @spec transform_dictionary(step :: t, dictionary :: Dictionary.t()) ::
          {:ok, Dictionary.t()} | {:error, term}
  def transform_dictionary(step, dictionary)

  @spec transform(step :: t, context :: Transform.Steps.Context.t()) ::
          {:ok, Transform.Steps.Context.t()} | {:error, term}
  def transform(step, context)
end
