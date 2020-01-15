defmodule Gather.ExtractionTest do
  use Gather.Case
  import Mox
  require Temp.Env

  alias Gather.Extraction

  @moduletag capture_log: true

  Temp.Env.modify([
    %{app: :service_gather, key: Gather.Extraction, update: fn config ->
       Keyword.put(config, :writer, Gather.WriterMock)
       |> Keyword.put(:chunk_size, 10)
     end}
  ])

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    Process.flag(:trap_exit, true)

    on_exit(fn ->
      __cleanup_supervisor__()
    end)

    :ok
  end

  test "sends chunks of data to writer and then dies" do
    test = self()

    Gather.WriterMock
    |> expect(:start_link, 1, fn _ -> Agent.start_link(fn -> :dummy end) end)
    |> expect(:write, 10, fn server, messages ->
      send(test, {:write, server, messages})
      :ok
    end)

    extract =
      Extract.new!(
        id: "extract-1",
        dataset_id: "ds1",
        name: "happy-path",
        destination: "topic1",
        steps: [
          %{
            "step" => "Fake.Step",
            "values" => Stream.cycle([%{"one" => 1}]) |> Stream.take(100)
          }
        ]
      )

    {:ok, pid} = Extraction.start_link(extract: extract)

    assert_receive {:EXIT, ^pid, :normal}, 2_000

    assert_down(pid)
  end

  test "when child write return error tuple it retries and then dies" do
    Gather.WriterMock
    |> expect(:start_link, 4, fn _ -> Agent.start_link(fn -> :dummy end) end)
    |> expect(:write, 4, fn _server, _messages -> {:error, "failure to write"} end)

    extract =
      Extract.new!(
        id: "extract-1",
        dataset_id: "ds1",
        name: "test-extract",
        destination: "topic1",
        steps: [
          %{
            "step" => "Fake.Step",
            "values" => [
              %{"name" => "joe", "age" => 21},
              %{"name" => "pete", "age" => 28}
            ]
          }
        ]
      )

    {:ok, pid} = Extraction.start_link(extract: extract)

    assert_receive {:EXIT, ^pid, "failure to write"}, 10_000

    assert_down(pid)
  end

  test "when child writer fails to start extraction is retried" do
    Gather.WriterMock
    |> expect(:start_link, 4, fn _ -> {:error, "bad process"} end)

    extract =
      Extract.new!(
        id: "extract-1",
        dataset_id: "ds1",
        name: "test-extract",
        destination: "topic1",
        steps: [
          %{
            "step" => "Fake.Step",
            "values" => [
              %{"name" => "joe", "age" => 21},
              %{"name" => "pete", "age" => 28}
            ]
          }
        ]
      )

    {:ok, pid} = Extraction.start_link(extract: extract)

    assert_receive {:EXIT, ^pid, "bad process"}, 10_000
    assert_down(pid)
  end

  defp assert_down(pid) do
    ref = Process.monitor(pid)
    Process.exit(pid, :kill)
    assert_receive {:DOWN, ^ref, _, _, _}
  end
end
