defmodule Receive.InitTest do
  use ExUnit.Case

  @instance Receive.Application.instance()

  setup do
    Process.flag(:trap_exit, true)

    on_exit(fn ->
      Receive.Accept.Supervisor.kill_all_children()
    end)

    :ok
  end

  test "should start any existing accepts" do
    accepts = [
      Accept.new!(
        id: "acc1",
        dataset_id: "init_acc1",
        subset_id: "acc1_ss",
        destination: Destination.Fake.new!(),
        connection: Accept.Udp.new!(port: 6789)
      ),
      Accept.new!(
        id: "acc2",
        dataset_id: "init_acc2",
        subset_id: "acc2_ss",
        destination: Destination.Fake.new!(),
        connection: Accept.Udp.new!(port: 7890)
      )
    ]

    Brook.Test.with_event(@instance, fn ->
      Enum.each(accepts, &Receive.Accept.Store.persist/1)
    end)

    start_supervised({Receive.Init, name: :init_test})

    Enum.each(accepts, fn %{destination: %{id: id}} ->
      assert_receive {:destination_start_link, ^id}, 5_000
    end)
  end
end
