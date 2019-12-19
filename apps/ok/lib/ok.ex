defmodule Ok do

  @spec map({:ok, term} | {:error, term}, (term -> term)) :: {:ok, term} | {:error, term}
  def map({:ok, value}, function) when is_function(function, 1) do
    {:ok, function.(value)}
  end

  def map({:error, _reason} = error, _function), do: error

  @spec reduce(Enum.t(), Enum.acc(), (Enum.element(), Enum.acc() -> {:ok, Enum.acc()} | {:error, term})) :: {:ok, Enum.acc()} | {:error, term}
  def reduce(enum, initial, function) do
    Enum.reduce_while(enum, {:ok, initial}, fn item, {:ok, acc} ->
      case function.(item, acc) do
        {:ok, new_acc} -> {:cont, {:ok, new_acc}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
end
