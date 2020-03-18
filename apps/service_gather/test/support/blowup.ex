defmodule Extract.Blowup do
  use Definition, schema: Extract.Blowup.Schema
  defstruct []

  defimpl Extract.Step, for: __MODULE__ do
    import Extract.Context

    def execute(_, context) do
      set_source(context, fn _ -> raise RuntimeError, "blowup" end)
      |> Ok.ok()
    end
  end
end

defmodule Extract.Blowup.Schema do
  use Definition.Schema

  @impl true
  def s do
    schema(%Extract.Blowup{})
  end
end
