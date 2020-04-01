defmodule Define.Model.DataDefinitionView do
  use Definition, schema: Define.DataDefinitionView.V1
  alias Define.Model.{ExtractView, PersistView, TransformView}

  @type t :: %__MODULE__{
          version: integer,
          dataset_id: String.t(),
          subset_id: String.t(),
          extract: ExtractView.t(),
          transform: TransformView.t(),
          persist: PersistView.t()
        }

  @derive Jason.Encoder
  defstruct version: 1,
            dataset_id: "",
            subset_id: "default",
            extract: %ExtractView{},
            transform: %TransformView{},
            persist: %PersistView{}
end

defmodule Define.DataDefinitionView.V1 do
  use Definition.Schema
  alias Define.Model.{ExtractView, TransformView, PersistView}

  @impl true
  def s do
    schema(%Define.Model.DataDefinitionView{
      version: version(1),
      dataset_id: string(),
      subset_id: string(),
      extract: of_struct(ExtractView),
      transform: of_struct(TransformView),
      persist: of_struct(PersistView)
    })
  end
end
