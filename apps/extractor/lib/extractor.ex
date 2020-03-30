defmodule Extractor do
  use Definition, schema: Extractor.V1

  @type t :: %__MODULE__{
          pid: pid,
          steps: list(Extract.Step.t())
        }

  defstruct pid: nil,
            steps: []

  defimpl Source do
    defdelegate start_link(t, context), to: Extractor.Server
    defdelegate stop(t, server), to: Extractor.Server
    defdelegate delete(t), to: Extractor.Server
  end
end

defmodule Extractor.V1 do
  use Definition.Schema

  def s do
    schema(%Extractor{
      steps: coll_of(impl_of(Extract.Step))
    })
  end
end
