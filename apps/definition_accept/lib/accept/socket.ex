defmodule Accept.Socket do
  @type writer :: (list -> :ok | {:error, term})

  @callback handle_messages(message :: term, writer) :: :ok | {:error, term}

  defmacro __using__(_opts) do
    quote do
      import Accept.Socket, only: [batch_reached?: 2]
      @behaviour Accept.Socket

      @impl Accept.Socket
      def handle_messages(messages, writer) do
        writer.(messages)
      end

      defoverridable handle_messages: 2
    end
  end

  defmacro batch_reached?(current_batch, limit) do
    quote do
      length(unquote(current_batch)) + 1 >= unquote(limit)
    end
  end
end
