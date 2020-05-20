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
      do_decode(t, messages, t.skip_first_line and !already_skipped?())
    end

    defp do_decode(t, messages, false = _should_skip?) do
      Enum.map(messages, &parse(&1, t.headers))
    end

    defp do_decode(t, messages, true = _should_skip?) do
      mark_skipped()

      messages
      |> Enum.drop(1)
      |> Enum.map(fn message -> parse(message, t.headers) end)
    end

    defp already_skipped?() do
      Process.get(__MODULE__, %{}) |> Map.get(:have_skipped_headers, false)
    end

    defp mark_skipped() do
      Process.put(__MODULE__, %{:have_skipped_headers => true})
    end

    # def decode(t, messages) do
    #   if skip_line?(t) do
    #     messages
    #     |> Enum.drop(1)
    #     |> Enum.map(fn message -> parse(message, t.headers) end)
    #   else
    #     Enum.map(messages, fn message -> parse(message, t.headers) end)
    #   end
    # end

    # def skip_line?(%{skip_first_line: false}), do: false
    #
    # def skip_line?(_t) do
    #   unless Process.get(:have_skipped_headers) do
    #     Process.put(:have_skipped_headers, true)
    #     true
    #   end
    # end

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
