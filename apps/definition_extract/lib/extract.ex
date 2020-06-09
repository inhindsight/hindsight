defmodule Extract do
  @moduledoc """
  Object representing the extraction (think ETL) of data. Use `new/1` to create a
  new instance.

  ## Init options

  * `id` - ID of this instance of an extraction. Typically a UUID.
  * `dataset_id` - Dataset identifier.
  * `subset_id` - Dataset's subset identifier.
  * `source` - A `Source.t()` impl from which data will be extracted.
  * `decoder` - A `Decoder.t()` impl for decoding extracted data's format.
  * `destination` - A `Destination.t()` impl to which the data will be written.
  * `dictionary` - A `Dictionary.t()` impl describing the data's schema.
  """
  use Definition, schema: Extract.V1
  use JsonSerde, alias: "extract"

  @type uuid :: String.t()

  @type t :: %Extract{
          version: integer,
          id: uuid,
          dataset_id: String.t(),
          subset_id: String.t(),
          source: Source.t(),
          decoder: Decoder.t(),
          destination: Destination.t(),
          dictionary: Dictionary.t()
        }

  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            subset_id: nil,
            source: nil,
            decoder: nil,
            destination: nil,
            dictionary: Dictionary.from_list([])

  @impl Definition
  def on_new(%{dictionary: list} = extract) when is_list(list) do
    Map.put(extract, :dictionary, Dictionary.from_list(list))
    |> Ok.ok()
  end

  def on_new(extract), do: Ok.ok(extract)
end
