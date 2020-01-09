defmodule Writer.DLQ.DeadLetter do
  @type t :: %__MODULE__{
          version: integer,
          dataset_id: String.t(),
          original_message: term,
          app_name: String.Chars.t(),
          stacktrace: list,
          reason: Exception.t() | String.Chars.t(),
          timestamp: DateTime.t()
        }

  defstruct version: 1,
            dataset_id: nil,
            original_message: nil,
            app_name: nil,
            stacktrace: [],
            reason: nil,
            timestamp: nil

  @spec new(keyword | map) :: t
  def new(values) do
    struct(__MODULE__, values)
  end
end
