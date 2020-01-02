defmodule Ok do
  @type ok :: {:ok, term}
  @type error :: {:error, term}
  @type result :: ok | error

  @spec ok(term) :: ok
  def ok(value), do: {:ok, value}

  @spec error(term) :: error
  def error(reason), do: {:error, reason}

  @spec map(result, (term -> term)) :: result
  def map({:ok, value}, function) when is_function(function, 1) do
    {:ok, function.(value)}
  end

  def map({:error, _reason} = error, _function), do: error

  @spec reduce(
          Enum.t(),
          Enum.acc(),
          (Enum.element(), Enum.acc() -> {:ok, Enum.acc()} | {:error, term})
        ) :: {:ok, Enum.acc()} | {:error, term}
  def reduce(enum, initial, function) do
    Enum.reduce_while(enum, {:ok, initial}, fn item, {:ok, acc} ->
      case function.(item, acc) do
        {:ok, new_acc} -> {:cont, {:ok, new_acc}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  @spec transform(Enum.t(), (Enum.element() -> {:ok, Enum.element()} | {:error, term})) ::
          {:ok, Enum.t()} | {:error, term}
  def transform(enum, function) when is_list(enum) and is_function(function, 1) do
    reduce(enum, [], fn item, acc ->
      function.(item)
      |> map(fn result -> [result | acc] end)
    end)
    |> map(&Enum.reverse/1)
  end

  @spec all?(Enum.t()) :: boolean
  def all?(enum) do
    not Enum.any?(enum, &match?({:error, _}, &1))
  end
end
