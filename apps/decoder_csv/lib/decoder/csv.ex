NimbleCSV.define(Decoder.Csv.Parser, [])

defmodule Decoder.Csv do
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
    def decode(t, stream) do
      stream
      |> Stream.transform(%{skip: t.skip_first_line}, fn chunk, %{skip: skip} = acc ->
        parsed_chunk = parse_chunk(chunk, t.headers, skip)
        {[parsed_chunk], %{acc | skip: false}}
      end)
    end

    defp parse_chunk(chunk, headers, skip) do
      {buffer, _} =
        Enum.reduce(chunk, {[], skip}, fn
          message, {buffer, false} ->
            {[parse(message, headers) | buffer], false}

          _message, {buffer, true} ->
            {buffer, false}
        end)

      Enum.reverse(buffer)
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
