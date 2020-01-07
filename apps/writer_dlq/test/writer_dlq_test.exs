defmodule WriterDlqTest do
  use ExUnit.Case
  import Mox

  alias Writer.DLQ.DeadLetter

  setup :verify_on_exit!

  describe "start_link/1" do
    test "starts the topic writer properly" do
      test = self()

      WriterMock
      |> expect(:start_link, fn args ->
        send(test, {:start_link, args})
        {:ok, :pid}
      end)

      assert {:ok, :pid} == Writer.DLQ.start_link(endpoints: [localhost: 9092])

      assert_receive {:start_link, endpoints: [localhost: 9092], topic: "dead-letter-queue"}
    end
  end

  describe "write/3" do
    setup do
      test = self()

      WriterMock
      |> expect(:write, fn pid, messages, opts ->
        send(test, {:write, pid, messages, opts})
        :ok
      end)

      :ok
    end

    test "writes dead-letter" do
      now = DateTime.utc_now()

      dead_letters = [
        %DeadLetter{
          dataset_id: "ds1",
          app_name: "app1",
          original_message: %{"name" => "message1"},
          reason: "testing",
          timestamp: now
        }
      ]

      assert :ok == Writer.DLQ.write(:pid, dead_letters)
      assert_receive {:write, :pid, [dl], _opts}

      assert match?(
               %{
                 "dataset_id" => "ds1",
                 "original_message" => %{"name" => "message1"},
                 "app_name" => "app1",
                 "reason" => "testing",
                 "stacktrace" => _,
                 "timestamp" => _
               },
               Jason.decode!(dl)
             )
    end

    test "handles message that is not json encodable" do
      dead_letters = [
        %DeadLetter{
          dataset_id: "ds1",
          app_name: "app1",
          original_message: <<80, 75, 3, 4, 20, 0, 6, 0, 8, 0, 0, 0, 33, 0, 235, 122, 210>>,
          reason: "testing"
        }
      ]

      assert :ok == Writer.DLQ.write(:pid, dead_letters)
      assert_receive {:write, :pid, [dl], _opts}

      assert match?(
               %{
                 "original_message" => "<<80, 75, 3, 4, 20, 0, 6, 0, 8, 0, 0, 0, 33, 0, 235, 122, 210>>"
               },
               Jason.decode!(dl)
             )
    end
  end

end
