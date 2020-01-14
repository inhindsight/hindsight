defmodule Persist.Writer do
  @behaviour Writer

  alias Persist.Dictionary.Translator

  @config Application.get_env(:service_persist, __MODULE__, [])
  @writer Keyword.get(@config, :writer, Writer.Presto)
  @url Keyword.fetch!(@config, :url)
  @user Keyword.fetch!(@config, :user)
  @catalog Keyword.fetch!(@config, :catalog)
  @schema Keyword.fetch!(@config, :schema)

  @impl Writer
  def start_link(init_arg) do
    %Load.Persist{destination: destination, schema: schema} = Keyword.get(init_arg, :load)

    [
      url: @url,
      user: @user,
      catalog: @catalog,
      schema: @schema,
      table: destination,
      table_schema:
        Enum.map(schema, fn type ->
          result = Translator.translate(type)
          {result.name, result.type}
        end)
    ]
    |> @writer.start_link()
  end

  @impl Writer
  def child_spec(init_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [init_arg]}
    }
  end

  defdelegate write(server, messages, opts \\ []), to: @writer
end
