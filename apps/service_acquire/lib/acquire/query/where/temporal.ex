defmodule Acquire.Query.Where.Temporal do
  @moduledoc false
  import Acquire.Query.Where.Functions
  import Definition, only: [identifier: 2]
  alias Acquire.ViewState.Fields

  @spec to_queryable(
          dataset_id :: String.t(),
          subset_id :: String.t(),
          after_time :: String.t(),
          before_time :: String.t()
        ) :: Acquire.Queryable.t()
  def to_queryable(_, _, "", ""), do: nil

  def to_queryable(dataset_id, subset_id, after_time, before_time) do
    with {:ok, dictionary} <- identifier(dataset_id, subset_id) |> Fields.get() do
      Dictionary.get_by_type(dictionary, Dictionary.Type.Timestamp)
      |> Enum.map(&Enum.join(&1, "."))
      |> Enum.map(&to_queryable(&1, after_time, before_time))
      |> or_clause()
    end
  end

  defp to_queryable(field, after_time, before_time) do
    [
      after_clause(field, after_time),
      before_clause(field, before_time)
    ]
    |> Enum.filter(& &1)
    |> and_clause()
  end

  defp after_clause(_, ""), do: nil

  defp after_clause(field, time) do
    parsed_timestamp =
      time
      |> parameter()
      |> date_parse(literal("%Y-%m-%dT%H:%i:%S"))

    parsed_timestamp
    |> date_diff(field(field))
    |> gt(literal(0))
  end

  defp before_clause(_, ""), do: nil

  defp before_clause(field, time) do
    parsed_timestamp =
      time
      |> parameter()
      |> date_parse(literal("%Y-%m-%dT%H:%i:%S"))

    parsed_timestamp
    |> date_diff(field(field))
    |> lt(literal(0))
  end

  defp and_clause([item]), do: item

  defp and_clause(items) do
    Acquire.Query.Where.And.new!(conditions: items)
  end

  defp or_clause([item]), do: item

  defp or_clause(items) do
    Acquire.Query.Where.Or.new!(conditions: items)
  end
end
