defmodule Writer.DLQ.DeadLetter do
  use Definition, schema: Writer.DLQ.DeadLetter.V1

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
end

defmodule Writer.DLQ.DeadLetter.V1 do
  use Definition.Schema

  def s do
    schema(%Writer.DLQ.DeadLetter{
      version: spec(fn v -> v == 1 end),
      dataset_id: spec(is_binary() and not_empty?()),
      original_message: spec(not_nil?()),
      app_name: spec(is_binary() and not_empty?()),
      stacktrace: spec(is_list()),
      reason: spec(not_nil?())
    })
  end
end
