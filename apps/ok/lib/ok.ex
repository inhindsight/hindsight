defmodule Ok do
  @type ok :: {:ok, term}
  @type error :: {:error, term}
  @type result :: ok | error

  @spec ok(value) :: {:ok, value} when value: term
  def ok(value), do: {:ok, value}

  @spec error(reason) :: {:error, reason} when reason: term
  def error(reason), do: {:error, reason}

  @spec map(result | :ok, (term -> term)) :: result
  def map({:ok, value}, function) when is_function(function, 1) do
    {:ok, function.(value)}
  end

  def map({:error, _reason} = error, _function), do: error

  @spec map_if_error(result, (term -> term)) :: result
  def map_if_error({:error, reason}, function) when is_function(function, 1) do
    {:error, function.(reason)}
  end

  def map_if_error({:ok, _} = result, _function), do: result

  @spec reduce(
          Enum.t(),
          Enum.acc(),
          (Enum.element(), Enum.acc() -> {:ok, Enum.acc()} | error)
        ) :: {:ok, Enum.acc()} | error
  def reduce(enum, initial, function) do
    Enum.reduce_while(enum, {:ok, initial}, fn item, {:ok, acc} ->
      case function.(item, acc) do
        {:ok, new_acc} -> {:cont, {:ok, new_acc}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  @spec each(Enum.t(), (Enum.element() -> term | error)) :: :ok | error
  def each(enum, function) when is_function(function, 1) do
    Ok.reduce(enum, nil, fn item, acc ->
      case function.(item) do
        {:error, reason} -> {:error, reason}
        _ -> {:ok, acc}
      end
    end)
    |> case do
      {:ok, _} -> :ok
      error -> error
    end
  end

  def each({:error, _} = error), do: error

  @spec transform(Enum.t(), (Enum.element() -> {:ok, Enum.element()} | error)) ::
          {:ok, Enum.t()} | error
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
