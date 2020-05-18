NimbleCSV.define(Decoder.Csv.Parser, [])

defmodule Decoder.Csv do
  @moduledoc """
  Defines a `Decoder` impl for CSV data.

  ## Configuration

  * `headers` - Required. List of column headers.
  * `skip_first_line` - Is first line the headers? Defaults to `false`.
  """
  use Definition, schema: Decoder.Csv.V1

  @type t :: %__MODULE__{
          version: integer,
          headers: list,
          skip_first_line: boolean
        }

  @derive Jason.Encoder
  defstruct version: 1,
            headers: nil,
            skip_first_line: false

  defimpl Decoder, for: __MODULE__ do
    def lines_or_bytes(_t), do: :line

    def decode(t, messages) do
      messages
      |> Stream.transform(%{skip: t.skip_first_line}, fn chunk, acc ->
        if acc.skip do
          {[], %{acc | skip: false}}
        else
          parsed = parse(chunk, t.headers)
          {[parsed], acc}
        end
      end)
    end

    defp parse(data, headers) do
      Decoder.Csv.Parser.parse_string(data, skip_headers: false)
      |> List.flatten()
      |> zip(headers)
      |> Map.new()
    end

    defp zip(b, a) do
      Enum.zip(a, b)
    end
  end
end

defmodule Decoder.Csv.V1 do
  @moduledoc false
  use Definition.Schema

  @impl true
  def s do
    schema(%Decoder.Csv{
      version: version(1),
      headers: spec(is_list() and not_nil?()),
      skip_first_line: spec(is_boolean() and not_nil?())
    })
  end
end
