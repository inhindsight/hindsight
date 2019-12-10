defmodule Dataset.Schema.Validation do
  @moduledoc "TODO"

  @spec ts?(String.t()) :: boolean()
  def ts?(input) when is_binary(input) do
    case DateTime.from_iso8601(input) do
      {:ok, _, _} -> true
      _ -> false
    end
  end

  def ts?(_), do: false

  @spec temporal_range?([String.t()]) :: boolean()
  def temporal_range?([start, stop]) when is_binary(start) and is_binary(stop) do
    with {:ok, start_ts, _} <- DateTime.from_iso8601(start),
         {:ok, stop_ts, _} <- DateTime.from_iso8601(stop) do
      case DateTime.compare(start_ts, stop_ts) do
        :lt -> true
        :eq -> true
        :gt -> false
      end
    else
      _ -> false
    end
  end

  def temporal_range?(_), do: false

  @spec bbox?([float()]) :: boolean()
  def bbox?([x1, y1, x2, y2] = bbox) when x1 <= x2 and y1 <= y2 do
    Enum.all?(bbox, &is_float/1)
  end

  def bbox?(_), do: false

  @spec email?(String.t()) :: boolean()
  def email?(input) when is_binary(input) do
    Regex.match?(~r/^[A-Za-z0-9._%+-+']+@[A-Za-z0-9.-]+\.[A-Za-z]+$/, input)
  end

  def email?(_), do: false

  @spec not_empty?(String.t() | list() | map()) :: boolean()
  def not_empty?(""), do: false
  def not_empty?([]), do: false
  def not_empty?(map) when map == %{}, do: false

  def not_empty?(input) when is_binary(input) do
    case String.trim(input) do
      "" -> false
      _ -> true
    end
  end

  def not_empty?(_), do: true
end
