defmodule FakeAcceptConnection do
    defstruct connect: nil

    def new!() do
        struct(__MODULE__, %{})
    end

    defimpl Accept.Connection do
        def connect(_accept, _opts) do
            
        end
    end
end