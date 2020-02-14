defmodule Receive.InitTest do
  use ExUnit.Case
  import Mox
  require Temp.Env

  @instance Receive.Application.instance()

  Temp.Env.modify([
    %{
      app: :service_receive,
      key: Receive.SocketManager,
      set: [writer: Receive.WriterMock]
    }
  ])

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    Process.flag(:trap_exit, true)

    on_exit(fn ->
      Receive.Acception.Supervisor.kill_all_children()
    end)

    :ok
  end

  test "should start any existing accepts" do
    test = self()

    accepts = [
      Accept.new!(
        id: "acc1",
        dataset_id: "init_acc1",
        subset_id: "acc1_ss",
        destination: "init-topic1",
        connection: Accept.Udp.new!(port: 6789)
      ),
      Accept.new!(
        id: "acc2",
        dataset_id: "init_acc2",
        subset_id: "acc2_ss",
        destination: "init-topic2",
        connection: Accept.Udp.new!(port: 7890)
      )
    ]

    Brook.Test.with_event(@instance, fn ->
      Enum.each(accepts, &Receive.Acception.Store.persist/1)
    end)

    Receive.WriterMock
    |> stub(:start_link, fn args ->
      send(test, {:start_link, args})
      Agent.start_link(fn -> :dummy end)
    end)

    start_supervised({Receive.Init, name: :init_test})

    Enum.each(accepts, fn accept ->
      assert_receive {:start_link, [accept: ^accept]}, 5_000
    end)
  end
end
