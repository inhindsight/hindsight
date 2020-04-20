defmodule Receive.Event.HandlerTest do
  use ExUnit.Case
  use Placebo
  import AssertAsync
  import Events, only: [dataset_delete: 0, accept_start: 0, accept_end: 0]
  import Definition, only: [identifier: 1]
  alias Receive.ViewState

  @instance Receive.Application.instance()

  setup do
    allow Receive.Accept.Supervisor.start_child(any()), return: :ok
    on_exit(fn -> Brook.Test.clear_view_state(@instance, "accepts") end)

    accept =
      Accept.new!(
        id: "accept-1",
        dataset_id: "ds1",
        subset_id: "sb1",
        destination: Destination.Fake.new!(),
        connection:
          Accept.Websocket.new!(
            path: "/",
            port: 8080
          )
      )

    [accept: accept, key: identifier(accept)]
  end

  describe "handling #{accept_start()} event" do
    test "starts socket manager", %{accept: accept} do
      Brook.Test.send(@instance, accept_start(), "testing", accept)
      assert_called Receive.Accept.Supervisor.start_child({Receive.SocketManager, accept: accept})
    end

    test "stores accept state", %{accept: accept, key: key} do
      Brook.Test.send(@instance, accept_start(), "testing", accept)

      assert_async do
        assert {:ok, ^accept} = ViewState.Accepts.get(key)
      end
    end
  end

  describe "handling #{accept_end()} event" do
    test "terminates socket manager", %{accept: accept, key: key} do
      expect Receive.Accept.Registry.whereis(:"#{key}_manager"), return: :test_pid
      expect Receive.Accept.Supervisor.terminate_child(:test_pid), return: :ok

      Brook.Test.send(@instance, accept_end(), "testing", accept)
    end

    test "deletes accept state", %{accept: accept, key: key} do
      Brook.Test.send(@instance, accept_start(), "testing", accept)

      assert {:ok, stored} = ViewState.Accepts.get(key)
      refute is_nil(stored)

      Brook.Test.send(@instance, accept_end(), "testing", accept)

      assert {:ok, nil} = ViewState.Accepts.get(key)
    end
  end

  describe "handling #{dataset_delete()} event with view state" do
    setup do
      accept =
        Accept.new!(
          id: "accept-2",
          dataset_id: "ds2",
          subset_id: "sb2",
          destination: Destination.Fake.new!(),
          connection:
            Accept.Websocket.new!(
              path: "/",
              port: 8080
            )
        )

      delete =
        Delete.new!(
          id: "delete-2",
          dataset_id: accept.dataset_id,
          subset_id: accept.subset_id
        )

      Brook.Test.send(@instance, accept_start(), "testing", accept)

      [delete: delete, accept: accept, key: identifier(accept)]
    end

    test "terminates socket manager", %{key: key, delete: delete} do
      expect Receive.Accept.Registry.whereis(:"#{key}_manager"), return: :test_pid
      expect Receive.Accept.Supervisor.terminate_child(:test_pid), return: :ok

      Brook.Test.send(@instance, dataset_delete(), "testing", delete)
    end

    test "deletes destination", %{accept: accept, delete: delete, key: key} do
      destination = accept.destination

      Brook.Test.send(@instance, dataset_delete(), "testing", delete)

      assert_receive {:destination_delete, ^destination}, 1_000
      assert {:ok, nil} = ViewState.Destinations.get(key)
    end

    test "deletes accept object from view state", %{delete: delete, key: key} do
      Brook.Test.send(@instance, dataset_delete(), "testing", delete)
      assert {:ok, nil} = ViewState.Accepts.get(key)
    end
  end

  describe "handling #{dataset_delete()} event without view state" do
    setup do
      accept =
        Accept.new!(
          id: "accept-3",
          dataset_id: "ds3",
          subset_id: "sb3",
          destination: Destination.Fake.new!(),
          connection:
            Accept.Websocket.new!(
              path: "/",
              port: 8080
            )
        )

      delete =
        Delete.new!(
          id: "delete-3",
          dataset_id: accept.dataset_id,
          subset_id: accept.subset_id
        )

      Brook.Test.send(@instance, accept_start(), "testing", accept)
      Brook.Test.send(@instance, accept_end(), "testing", accept)

      [accept: accept, delete: delete, key: identifier(accept)]
    end

    test "deletes destination and destination state", %{accept: accept, delete: delete, key: key} do
      destination = accept.destination

      Brook.Test.send(@instance, dataset_delete(), "testing", delete)

      assert_receive {:destination_delete, ^destination}, 1_000
      assert {:ok, nil} = ViewState.Destinations.get(key)
    end
  end
end
