defmodule Gather.ExtractionTest do
  use Gather.Case
  use Placebo
  import Mox
  import AssertAsync
  require Temp.Env

  alias Gather.Extraction
  alias Extract.Http.File.Downloader
  alias Extract.Http.File.Downloader.Response

  @moduletag capture_log: true
  @download_file "./test.csv"

  alias Dlq.DeadLetter

  Temp.Env.modify([
    %{
      app: :service_gather,
      key: Gather.Extraction,
      update: fn config ->
        Keyword.put(config, :writer, Gather.WriterMock)
        |> Keyword.put(:dlq, DlqMock)
        |> Keyword.put(:chunk_size, 10)
      end
    }
  ])

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    Process.flag(:trap_exit, true)

    on_exit(fn ->
      Gather.Extraction.Supervisor.kill_all_children()
      File.rm(@download_file)
    end)

    :ok
  end

  test "normalizes chunks of data to writer and then dies" do
    test = self()

    Gather.WriterMock
    |> stub(:start_link, fn _ -> Agent.start_link(fn -> :dummy end) end)
    |> stub(:write, fn server, messages, opts ->
      send(test, {:write, server, messages, opts})
      :ok
    end)

    extract =
      Extract.new!(
        id: "extract-1",
        dataset_id: "ds1",
        subset_id: "happy-path",
        destination: "topic1",
        steps: [
          %Fake.Step{
            pid: self(),
            chunk_size: 10,
            values: Stream.cycle([%{"one" => "1"}]) |> Stream.take(100)
          }
        ],
        dictionary: [
          Dictionary.Type.Integer.new!(name: "one")
        ]
      )

    {:ok, pid} = Extraction.start_link(extract: extract)

    assert_receive {:EXIT, ^pid, :normal}, 2_000
    expected = Enum.map(1..10, fn _ -> %{"one" => 1} end)
    Enum.each(1..10, fn _ -> assert_receive {:write, _, ^expected, _} end)

    originals = Enum.map(1..10, fn _ -> Extract.Message.new(data: %{"one" => "1"}) end)
    Enum.each(1..10, fn _ -> assert_receive {:after, ^originals} end)

    assert_down(pid)
  end

  test "any messages failing normalization will be written to dlq" do
    test = self()

    Gather.WriterMock
    |> stub(:start_link, fn _ -> Agent.start_link(fn -> :dummy end) end)
    |> stub(:write, fn server, messages, opts ->
      send(test, {:write, server, messages, opts})
      :ok
    end)

    DlqMock
    |> stub(:write, fn messages ->
      send(test, {:dlq, messages})
    end)

    extract =
      Extract.new!(
        id: "extract-1",
        dataset_id: "ds1",
        subset_id: "happy-path",
        destination: "topic1",
        steps: [
          %Fake.Step{pid: self(), values: [%{"one" => "2"}, %{"one" => "abc"}]}
        ],
        dictionary: [
          Dictionary.Type.Integer.new!(name: "one")
        ]
      )

    {:ok, pid} = Extraction.start_link(extract: extract)
    assert_receive {:EXIT, ^pid, :normal}, 2_000

    assert_receive {:write, _, [%{"one" => 2}], _}

    expected_dead_letter =
      DeadLetter.new(
        dataset_id: "ds1",
        subset_id: "happy-path",
        original_message: %{"one" => "abc"},
        app_name: "service_gather",
        reason: %{"one" => :invalid_integer}
      )
      |> Map.merge(%{stacktrace: nil, timestamp: nil})

    assert_receive {:dlq, [actual_dead_letter]}

    assert expected_dead_letter ==
             actual_dead_letter |> Map.merge(%{stacktrace: nil, timestamp: nil})
  end

  test "when child write return error tuple it retries and then dies" do
    Gather.WriterMock
    |> stub(:start_link, fn _ -> Agent.start_link(fn -> :dummy end) end)
    |> expect(:write, 4, fn _server, _messages, _opts -> {:error, "failure to write"} end)

    extract =
      Extract.new!(
        id: "extract-1",
        dataset_id: "ds1",
        subset_id: "test-extract",
        destination: "topic1",
        steps: [
          %Fake.Step{
            values: [
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
        subset_id: "test-extract",
        destination: "topic1",
        steps: [
          %Fake.Step{
            values: [
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

  test "cleans up downloaded file after extract complete" do
    Gather.WriterMock
    |> stub(:start_link, fn _ -> Agent.start_link(fn -> :dummy end) end)

    request_url = "http://example/download/path"

    allow Downloader.download(request_url, to: @download_file, headers: []),
      return: write_temp_file(@download_file)

    allow Temp.path(any()), return: {:ok, @download_file}

    extract =
      Extract.new!(
        id: "extract-1",
        dataset_id: "ds1",
        subset_id: "happy-path",
        destination: "topic1",
        steps: [
          Extract.Http.Get.new!(url: request_url),
          Extract.Decode.Json.new!([])
        ],
        dictionary: [
          Dictionary.Type.Integer.new!(name: "one")
        ]
      )

    start_supervised({Extraction, [extract: extract]})

    assert_async sleep: 1000 do
      refute File.exists?(@download_file)
    end
  end

  test "cleans up downloaded file after an extraction stream failure" do
    Gather.WriterMock
    |> stub(:start_link, fn _ -> Agent.start_link(fn -> :dummy end) end)

    request_url = "http://example/download/path"

    allow Downloader.download(request_url, to: @download_file, headers: []),
      return: write_temp_file(@download_file)

    allow Temp.path(any()), return: {:ok, @download_file}

    extract =
      Extract.new!(
        id: "extract-1",
        dataset_id: "ds1",
        subset_id: "failure",
        destination: "topic1",
        steps: [
          Extract.Http.Get.new!(url: request_url),
          Extract.Blowup.new!([])
        ]
      )

    start_supervised({Extraction, [extract: extract]})

    assert_async sleep: 1_000 do
      refute File.exists?(@download_file)
    end
  end

  defp assert_down(pid) do
    ref = Process.monitor(pid)
    Process.exit(pid, :kill)
    assert_receive {:DOWN, ^ref, _, _, _}
  end

  defp write_temp_file(file_name) do
    File.write(file_name, "")
    {:ok, %Response{destination: file_name}}
  end
end
