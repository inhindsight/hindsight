defmodule Source.Handler do
  @type impl :: module

  @callback handle_message(map) :: {:ok, map} | {:error, term}
  @callback handle_batch(list(map)) :: :ok

  defmacro __using__(_opts) do
    quote do
      @behaviour Source.Handler

      def handle_message(message), do: Ok.ok(message)
      defoverridable Source.Handler

    end
  end

end
