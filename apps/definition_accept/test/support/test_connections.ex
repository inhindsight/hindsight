defmodule Test.Connections do
  defmodule SomeProtocol do
    defstruct [:port, :key]

    defimpl Accept.Connection, for: SomeProtocol do
      def connect(settings), do: [port: settings.port, key: settings.key]
    end
  end

  defmodule PooledProtocol do
    defstruct [:port, :pool]

    defimpl Accept.Connection, for: PooledProtocol do
      def connect(settings), do: [port: settings.port, pool: settings.pool]
    end
  end
end
