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

  Temp.Env.modify([
    %{
      app: :service_gather,
      key: Gather.Extraction.SourceStream.SourceHandler,
      update: fn config ->
        Keyword.put(config, :dlq, DlqMock)
        |> Keyword.put(:chunk_size, 10)
      end
    }
  ])

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    Process.flag(:trap_exit, true)

    Gather.Application.instance() |> Brook.Test.register()

    on_exit(fn ->
      Gather.Extraction.Supervisor.kill_all_children()
      File.rm(@download_file)
    end)

    :ok
  end

  test "normalizes chunks of data to writer and then dies" do
    extract =
      Extract.new!(
        id: "extract-1",
        dataset_id: "ds1",
        subset_id: "happy-path",
        source: Source.Fake.new!(),
        decoder: Decoder.JsonLines.new!([]),
        destination: Destination.Fake.new!(),
        dictionary: [
          Dictionary.Type.Integer.new!(name: "one")
        ]
      )

    {:ok, pid} = Extraction.start_link(extract: extract)

    assert_receive {:source_start_link, _, _}, 1_000

    messages = Stream.cycle([%{"one" => "1"}]) |> Stream.take(10) |> Enum.to_list()

    Enum.each(1..10, fn _ ->
      Source.Fake.inject_messages(extract.source, messages)
    end)

    expected = Enum.map(1..10, fn _ -> %{"one" => 1} end)
    Enum.each(1..10, fn _ -> assert_receive {:destination_write, ^expected} end)

    Source.Fake.stop(extract.source)
    assert_receive {:EXIT, ^pid, :normal}, 2_000

    assert_down(pid)
  end

  test "any messages failing normalization will be written to dlq" do
    test = self()

    DlqMock
    |> stub(:write, fn messages ->
      send(test, {:dlq, messages})
    end)

    extract =
      Extract.new!(
        id: "extract-1",
        dataset_id: "ds1",
        subset_id: "happy-path",
        source: Source.Fake.new!(messages: [%{"one" => "2"}, %{"one" => "abc"}]),
        decoder: Decoder.JsonLines.new!([]),
        destination: Destination.Fake.new!(),
        dictionary: [
          Dictionary.Type.Integer.new!(name: "one")
        ]
      )

    {:ok, pid} = Extraction.start_link(extract: extract)

    assert_receive {:destination_write, [%{"one" => 2}]}

    expected_dead_letter =
      DeadLetter.new(
        dataset_id: "ds1",
        subset_id: "happy-path",
        original_message: %{"one" => "abc"},
        app_name: "service_gather",
        reason: %{"one" => :invalid_integer},
        stacktrace: nil,
        timestamp: nil
      )
      |> Map.merge(%{stacktrace: nil, timestamp: nil})

    assert_receive {:dlq, [actual_dead_letter]}

    assert expected_dead_letter ==
             actual_dead_letter |> Map.merge(%{stacktrace: nil, timestamp: nil})

    Source.Fake.stop(extract.source)
    assert_receive {:EXIT, ^pid, _}
  end

  test "when child write return error tuple it retries and then dies" do
    source =
      Source.Fake.new!(
        messages: [
          %{"name" => "joe", "age" => 21},
          %{"name" => "pete", "age" => 28}
        ]
      )

    extract =
      Extract.new!(
        id: "extract-1",
        dataset_id: "ds1",
        subset_id: "test-extract",
        source: source,
        decoder: Decoder.JsonLines.new!([]),
        destination: Destination.Fake.new!(write: "bad write")
      )

    {:ok, pid} = Extraction.start_link(extract: extract)

    assert_receive {:EXIT, ^pid, {:badmatch, {:error, "bad write"}}}, 5_000

    assert_down(pid)
  end

  test "when child writer fails to start extraction is retried" do
    extract =
      Extract.new!(
        id: "extract-1",
        dataset_id: "ds1",
        subset_id: "test-extract",
        source:
          Source.Fake.new!(
            messages: [
              %{"name" => "joe", "age" => 21},
              %{"name" => "pete", "age" => 28}
            ]
          ),
        decoder: Decoder.JsonLines.new!([]),
        destination: Destination.Fake.new!(start_link: "bad start")
      )

    {:ok, pid} = Extraction.start_link(extract: extract)

    assert_receive {:EXIT, ^pid, "bad start"}, 10_000
    assert_down(pid)
  end

  test "cleans up downloaded file after extract complete" do
    request_url = "http://example/download/path"

    allow Downloader.download(request_url, to: @download_file, headers: []),
      return: write_temp_file(@download_file)

    allow Temp.path(any()), return: {:ok, @download_file}

    extract =
      Extract.new!(
        id: "extract-1",
        dataset_id: "ds1",
        subset_id: "happy-path",
        source:
          Extractor.new!(
            steps: [
              Extract.Http.Get.new!(url: request_url)
            ]
          ),
        decoder: Decoder.Json.new!([]),
        destination: Destination.Fake.new!(),
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
    request_url = "http://example/download/path"

    allow Downloader.download(request_url, to: @download_file, headers: []),
      return: write_temp_file(@download_file)

    allow Temp.path(any()), return: {:ok, @download_file}

    extract =
      Extract.new!(
        id: "extract-1",
        dataset_id: "ds1",
        subset_id: "failure",
        source:
          Extractor.new!(
            steps: [
              Extract.Http.Get.new!(url: request_url),
              Extract.Blowup.new!([])
            ]
          ),
        decoder: Decoder.Noop.new(),
        destination: Destination.Fake.new!()
      )

    {:ok, _pid} = Extraction.start_link(extract: extract)

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
