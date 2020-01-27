defprotocol Transform.Step do
  @spec transform_dictionary(step :: t, dictionary :: Dictionary.t()) ::
          {:ok, Dictionary.t()} | {:error, term}
  def transform_dictionary(step, dictionary)

  @spec transform_function(step :: t, dictionary :: Dictionary.t()) ::
          {:ok, (Enumerable.t() -> Enumerable.t())} | {:error, term}
  def transform_function(step, dictionary)
end
