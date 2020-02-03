defmodule Test.Connections do
  defmodule SomeProtocol do
    defstruct [:port, :key]

    defimpl Accept.Connection, for: SomeProtocol do
      def connect(settings) do
        [{SomeProtocol, [port: settings.port, key: settings.key]}]
      end
    end
  end

  defmodule PooledProtocol do
    defstruct [:port, :pool]

    defimpl Accept.Connection, for: PooledProtocol do
      def connect(settings) do
        port = settings.port
        listener = :"pooled_#{port}"

        [
          {PooledProtocol, [port: port, name: listener]},
          Enum.map(0..(settings.pool - 1), &worker_spec(&1, listener))
        ]
        |> List.flatten()
      end

      defp worker_spec(id, listener) do
        %{id: id, start: {PooledWorker, :start_link, [listener: listener]}}
      end
    end
  end
end
