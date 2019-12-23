defmodule Decode.JsonLines do
  defstruct []

  defimpl Extract.Step, for: Decode.JsonLines do
    import Extract.Steps.Context

    def execute(%Decode.JsonLines{} = step, %{stream: nil} = _context) do
      Extract.InvalidContextError.exception(
        message: "Invalid stream",
        step: step
      )
      |> Ok.error()
    end

    def execute(%Decode.JsonLines{}, context) do
      context.stream
      |> write_stream_to_file()
      |> Ok.map(&decode_from_file/1)
      |> Ok.map(&set_stream(context, &1))
    end

    defp write_stream_to_file(stream) do
      Temp.open([], fn file ->
        Enum.each(stream, &IO.binwrite(file, &1))
      end)
    end

    defp decode_from_file(file_path) do
      file_path
      |> File.stream!()
      |> Stream.transform(
        fn -> :ok end,
        fn line, acc -> {[Jason.decode!(line)], acc} end,
        fn _acc -> File.rm!(file_path) end
      )
    end
  end
end
