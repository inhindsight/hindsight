defmodule Extractor do
  @moduledoc """
  A `Source.t()` impl wrapping the extraction pipeline steps. This lets hindsight
  treat the extraction pipeline like any other `Source.t()` impl.

  ## Init options

  * `steps` - List of `Extract.Step.t()` impls composing the extraction pipeline.
  """
  use Definition, schema: Extractor.V1

  @type t :: %__MODULE__{
          steps: list(Extract.Step.t())
        }

  defstruct steps: []

  defimpl Source do
    defdelegate start_link(t, context), to: Extractor.Server
    defdelegate stop(t, server), to: Extractor.Server
    defdelegate delete(t), to: Extractor.Server
  end
end

defmodule Extractor.V1 do
  @moduledoc false
  use Definition.Schema

  def s do
    schema(%Extractor{
      steps: coll_of(impl_of(Extract.Step))
    })
  end
end
