defprotocol Transform.Step do
  @spec transform_dictionary(step :: t, dictionary :: Dictionary.t()) ::
          {:ok, Dictionary.t()} | {:error, term}
  def transform_dictionary(step, dictionary)

  @spec transform(step :: t, dictionary :: Dictionary.t(), stream :: Enumerable.t()) ::
          {:ok, Enumerable.t()} | {:error, term}
  def transform(step, dictionary, stream)
end
