defmodule Gather.WriterTest do
  use Gather.Case
  import Mox
  import ExUnit.CaptureLog

  alias Writer.DLQ.DeadLetter

  setup :verify_on_exit!

  describe "start_link/1" do
    test "starts child writer with proper arguments" do
      test = self()

      WriterMock
      |> expect(:start_link, fn args ->
        send(test, {:start_link, args})
      end)

      {:ok, extract} =
        Extract.new(
          version: 1,
          id: "extract-id-1",
          dataset_id: "test-ds1",
          name: "extract_name",
          destination: "topic-1",
          steps: [
            %{
              "step" => "Extract.Http.Get",
              "url" => "http://localhost/file.csv"
            },
            %{
              "step" => "Decode.Csv",
              "headers" => ["A", "B", "C"]
            }
          ]
        )

      Application.put_env(:service_gather, :kafka_endpoints, localhost: 9092)

      Gather.Writer.start_link(extract: extract, name: :joe)

      assert_receive {:start_link, actual}

      assert Keyword.get(actual, :endpoints) == [localhost: 9092]
      assert Keyword.get(actual, :topic) == "topic-1"
      assert Keyword.get(actual, :name) == :joe
    end
  end

  describe "write/3" do
    test "writes message to child writer" do
      stub_writer(:ok)

      messages = [
        Data.new!(version: 1, dataset_id: "ds1", extract_id: "A", payload: %{"one" => "two"}),
        Data.new!(version: 1, dataset_id: "ds1", extract_id: "A", payload: %{"one" => "three"})
      ]

      :ok = Gather.Writer.write(:pid, messages)

      assert_receive {:write, :pid, actuals}
      assert actuals == Enum.map(messages, &Jason.encode!/1)
    end

    test "write to DLQ if message cannot be encoded" do
      stub_writer(:ok)
      stub_dlq(:ok)

      messages = [
        Data.new!(
          version: 1,
          dataset_id: "ds1",
          extract_id: "A",
          payload: %{"one" => unencodable_value()}
        ),
        Data.new!(version: 1, dataset_id: "ds1", extract_id: "A", payload: %{"one" => "three"})
      ]

      :ok = Gather.Writer.write(:pid, messages)

      assert_receive {:write, :pid, actuals}
      assert actuals = messages |> Enum.at(1) |> Jason.encode!() |> List.wrap()

      assert_receive {:dlq, dead_letters}
      {:error, reason} = messages |> List.first() |> Jason.encode()

      expected =
        DeadLetter.new(
          dataset_id: "ds1",
          original_message: List.first(messages),
          app_name: Application.get_env(:service_gather, :app_name),
          reason: reason
        )

      assert dead_letters == [expected]
    end

    test "only writes to dlq if child writer call succeeds" do
      stub_writer({:error, "failure to write"})
      stub_dlq(:ok)

      messages = [
        Data.new!(
          version: 1,
          dataset_id: "ds1",
          extract_id: "A",
          payload: %{"one" => unencodable_value()}
        ),
        Data.new!(version: 1, dataset_id: "ds1", extract_id: "A", payload: %{"one" => "three"})
      ]

      assert {:error, "failure to write"} = Gather.Writer.write(:pid, messages)

      refute_receive {:dlq, _}
    end

    test "dlq returns error tuple" do
      stub_dlq({:error, "failure to dlq"})

      messages = [
        Data.new!(
          version: 1,
          dataset_id: "ds1",
          extract_id: "A",
          payload: %{"one" => unencodable_value()}
        )
      ]

      log =
        capture_log(fn ->
          assert :ok == Gather.Writer.write(:pid, messages)
        end)

      {:error, reason} = messages |> List.first() |> Jason.encode()

      expected_dead_letter =
        DeadLetter.new(
          dataset_id: "ds1",
          original_message: List.first(messages),
          app_name: Application.get_env(:service_gather, :app_name),
          reason: reason
        )

      expected_log = Enum.map([expected_dead_letter], &inspect/1) |> Enum.join("\n")

      assert log =~
               "Unable to send following messages to DLQ due to 'failure to dlq' :\n#{
                 expected_log
               }"
    end
  end

  defp stub_writer(return_value) do
    test = self()

    WriterMock
    |> stub(:write, fn server, messages ->
      send(test, {:write, server, messages})
      return_value
    end)
  end

  defp stub_dlq(return_value) do
    test = self()

    DlqMock
    |> stub(:write, fn messages ->
      send(test, {:dlq, messages})
      return_value
    end)
  end

  defp unencodable_value() do
    <<80, 75, 3, 4, 20, 0, 6, 0, 8, 0, 0, 0, 33, 0, 235, 122, 210>>
  end
end
