defmodule Decode.JsonLines do
  defstruct []

  defimpl Extract.Step, for: Decode.JsonLines do
    import Extract.Context

    def execute(%Decode.JsonLines{} = step, %{stream: nil} = _context) do
      Extract.InvalidContextError.exception(
        message: "Invalid stream",
        step: step
      )
      |> Ok.error()
    end

    def execute(%Decode.JsonLines{}, context) do
      {:ok, file_path} =
        Temp.open([], fn file ->
          Enum.each(context.stream, &IO.binwrite(file, &1))
        end)

      new_stream =
        file_path
        |> File.stream!()
        |> Stream.transform(
          fn -> :ok end,
          fn line, acc -> {[Jason.decode!(line)], acc} end,
          fn _acc ->
            File.rm!(file_path)
          end
        )

      set_stream(context, new_stream)
      |> Ok.ok()
    end
  end
end
