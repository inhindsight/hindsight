defmodule Gather.ExtractionTest do
  use ExUnit.Case
  import Mox

  alias Gather.Extraction

  @moduletag capture_log: true

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    Process.flag(:trap_exit, true)
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
        steps: [
          %{
            "step" => "Fake.Step",
            "values" => Stream.cycle([%{"one" => 1}]) |> Stream.take(100)
          }
        ]
      )

    {:ok, pid} = Extraction.start_link(extract: extract)

    assert_receive {:EXIT, ^pid, :normal}, 2_000
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
  end

  test "when child writer fails to start extraction is retried" do
    Gather.WriterMock
    |> expect(:start_link, 4, fn _ -> {:error, "bad process"} end)

    extract =
      Extract.new!(
        id: "extract-1",
        dataset_id: "ds1",
        name: "test-extract",
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
  end
end
