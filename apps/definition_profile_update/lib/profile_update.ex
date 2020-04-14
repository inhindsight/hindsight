defmodule Profile.Update do
  @moduledoc """
  Object representing the profiling of data. Use `new/1` to create a new instance.

  ## Init options

  * `dataset_id` - Dataset identifier.
  * `subset_id` - Dataset's subset identifier.
  """
  use Definition, schema: Profile.Update.V1

  @type t :: %__MODULE__{
          version: integer,
          dataset_id: String.t(),
          subset_id: String.t(),
          updated: String.t(),
          stats: map()
        }

  defstruct version: 1,
            dataset_id: nil,
            subset_id: nil,
            updated: nil,
            stats: %{}

  def on_new(update) do
    Map.put(
      update,
      :updated,
      NaiveDateTime.utc_now()
      |> NaiveDateTime.to_iso8601()
    )
    |> Ok.ok()
  end
end

defmodule Profile.Update.V1 do
  @moduledoc false
  use Definition.Schema

  def s do
    schema(%Profile.Update{
      version: version(1),
      dataset_id: required_string(),
      subset_id: required_string(),
      updated: required_string(),
      stats: spec(is_map())
    })
  end
end
