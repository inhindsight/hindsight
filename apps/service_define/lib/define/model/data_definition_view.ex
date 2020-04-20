defmodule Define.Model.DataDefinitionView do
  @moduledoc """
  Represents an aggregate of all events pertaining to a specific dataset.
  """
  use Definition, schema: Define.DataDefinitionView.V1
  alias Define.Model.{ExtractView, LoadView, TransformView}

  @type t :: %__MODULE__{
          version: integer,
          dataset_id: String.t(),
          subset_id: String.t(),
          extract: ExtractView.t(),
          transform: TransformView.t(),
          load: LoadView.t()
        }

  @derive Jason.Encoder
  defstruct version: 1,
            dataset_id: "",
            subset_id: "default",
            extract: %ExtractView{},
            transform: %TransformView{},
            load: %LoadView{}
end

defmodule Define.DataDefinitionView.V1 do
  @moduledoc false
  use Definition.Schema
  alias Define.Model.{ExtractView, TransformView, LoadView}

  @impl true
  def s do
    schema(%Define.Model.DataDefinitionView{
      version: version(1),
      dataset_id: string(),
      subset_id: string(),
      extract: of_struct(ExtractView),
      transform: of_struct(TransformView),
      load: of_struct(LoadView)
    })
  end
end
