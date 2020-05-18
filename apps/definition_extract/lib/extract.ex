defmodule Extract do
  use Definition, schema: Extract.V1

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
