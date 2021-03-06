NimbleCSV.define(Decoder.Csv.Parser, [])

defmodule Decoder.Csv do
  @moduledoc """
  Defines a `Decoder` impl for CSV data.

  ## Configuration

  * `headers` - Required. List of column headers.
  * `skip_first_line` - Is first line the headers? Defaults to `false`.
  """
  use Definition, schema: Decoder.Csv.V1
  use JsonSerde, alias: "decoder_csv"

  @type t :: %__MODULE__{
          version: integer,
          headers: list,
          skip_first_line: boolean
        }

  @derive Jason.Encoder
  defstruct version: 1,
            headers: nil,
            skip_first_line: false

  defimpl Decoder do
    def lines_or_bytes(_t), do: :line

    def decode(t, messages) do
      process_headers(messages, should_skip?(t))
      |> Enum.map(&parse(&1, t.headers))
    end

    defp process_headers(messages, false = _should_skip?), do: messages

    defp process_headers(messages, true = _should_skip?) do
      mark_skipped()

      Enum.drop(messages, 1)
    end

    defp should_skip?(t) do
      t.skip_first_line and !already_skipped?()
    end

    defp already_skipped?() do
      Process.get(__MODULE__, %{}) |> Map.get(:have_skipped_headers, false)
    end

    defp mark_skipped() do
      Process.put(__MODULE__, %{have_skipped_headers: true})
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
