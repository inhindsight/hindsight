defmodule Persist.Writer do
  @behaviour Writer
  use Properties, otp_app: :service_persist

  alias Persist.Dictionary.Translator

  getter(:writer, default: Writer.Presto)
  getter(:url, required: true)
  getter(:user, required: true)
  getter(:catalog, required: true)
  getter(:schema, required: true)

  @impl Writer
  def start_link(init_arg) do
    %Load.Persist{destination: destination, schema: schema} = Keyword.get(init_arg, :load)

    [
      url: url(),
      user: user(),
      catalog: catalog(),
      schema: schema(),
      table: destination,
      table_schema:
        Enum.map(schema, fn type ->
          result = Translator.translate(type)
          {result.name, result.type}
        end)
    ]
    |> writer().start_link()
  end

  @impl Writer
  def child_spec(init_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [init_arg]}
    }
  end

  @impl Writer
  def write(server, messages, opts \\ []) do
    writer().write(server, messages, opts)
  end
end
