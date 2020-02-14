defmodule Receive.WriterTest do
  use ExUnit.Case
  import Mox
  require Temp.Env

  Temp.Env.modify([
    %{
      app: :service_receive,
      key: Receive.Writer,
      set: [writer: WriterMock, kafka_endpoints: [localhost: 9092]]
    }
  ])

  setup :verify_on_exit!

  describe "start_link/1" do
    test "starts child writer with proper arguments" do
      test = self()

      WriterMock
      |> expect(:start_link, fn args ->
        send(test, {:start_link, args})
      end)

      {:ok, accept} =
        Accept.new(
          id: "accept-id-1",
          dataset_id: "test-ds1",
          subset_id: "test-ss1",
          destination: "topic-1",
          connection: Accept.Udp.new!(port: 6789)
        )

      Receive.Writer.start_link(accept: accept, name: :ricky_bobby)

      assert_receive {:start_link, actual}

      assert Keyword.get(actual, :endpoints) == [localhost: 9092]
      assert Keyword.get(actual, :topic) == "topic-1"
      assert Keyword.get(actual, :name) == :ricky_bobby
    end
  end

  describe "write/3" do
    setup do
      test = self()

      WriterMock
      |> stub(:write, fn server, messages ->
        send(test, {:write, server, messages})
        :ok
      end)

      :ok
    end

    test "writes message to child writer" do
      messages = [
        "{\"payload\":\"je93iuj2\"}",
        "{\"payload\":\"928dj328v\"}"
      ]

      :ok = Receive.Writer.write(:pid, messages, dataset_id: "test-ds1")

      assert_receive {:write, :pid, actuals}
      assert Enum.all?(actuals, fn msg -> "{\"payload\"" <> _tail = msg end)
    end

    test "handles raw binary messages" do
      messages = [
        <<80, 75, 3, 4, 20, 0, 6, 0, 8, 0, 0, 0, 33, 0, 235, 122, 210>>,
        <<80, 75, 3, 4, 20, 0, 6, 0, 8, 0, 0, 0, 33, 0, 235, 122, 211>>
      ]

      :ok = Receive.Writer.write(:pid, messages, dataset_id: "test-ds2")

      assert_receive {:write, :pid, actuals}
      assert actuals == messages
    end
  end
end
