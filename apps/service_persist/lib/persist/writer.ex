defmodule Persist.Writer do
  @behaviour Writer
  use Properties, otp_app: :service_persist

  alias Persist.Dictionary.Translator

  getter(:writer, default: Writer.Presto)
  getter(:url, required: true)
  getter(:user, required: true)
  getter(:catalog, required: true)
  getter(:schema, required: true)

  @type init_opts :: [
          load: %Load.Persist{}
        ]

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
          result = Translator.translate_type(type)
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
    schema = Keyword.fetch!(opts, :schema)
    formatted_messages = Enum.map(messages, &format_message(schema, &1))
    writer().write(server, formatted_messages, opts)
  end

  defp format_message(schema, message) do
    schema
    |> Enum.map(fn %{name: name} = field -> {field, Map.get(message, name)} end)
    |> Enum.map(fn {field, value} -> Translator.translate_value(field, value) end)
  end
end
