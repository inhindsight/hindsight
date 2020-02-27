defmodule Persist.Writer.DirectUploadTest do
  use ExUnit.Case
  import Mox
  require Temp.Env

  setup :set_mox_global
  setup :verify_on_exit!

  Temp.Env.modify([
    %{
      app: :service_persist,
      key: Persist.DataFile,
      set: [
        impl: Persist.DataFileMock
      ]
    },
    %{
      app: :service_persist,
      key: Persist.TableCreator,
      set: [
        impl: Persist.TableCreatorMock
      ]
    },
    %{
      app: :service_persist,
      key: Persist.Uploader,
      set: [
        impl: Persist.UploaderMock
      ]
    }
  ])

  setup do
    Process.flag(:trap_exit, true)

    load =
      Load.Persist.new!(
        id: "1",
        dataset_id: "ds1",
        subset_id: "name",
        source: "topic1",
        destination: "table1"
      )

    [load: load]
  end

  test "will stop process when unable to create table", %{load: load} do
    Persist.TableCreatorMock
    |> stub(:create, fn _destination, _dictionary ->
      {:error, "failed to create"}
    end)

    {:error, "failed to create"} =
      Persist.Writer.DirectUpload.start_link(load: load, dictionary: :dictionary)
  end

  test "will stop process when unable to open datafile", %{load: load} do
    Persist.TableCreatorMock
    |> stub(:create, fn _, _ -> :ok end)

    Persist.DataFileMock
    |> stub(:open, fn _, _ -> {:error, "failed to open"} end)

    {:ok, pid} = Persist.Writer.DirectUpload.start_link(load: load, dictionary: :dictionary)
    assert {:error, "failed to open"} = Persist.Writer.DirectUpload.write(pid, [:data])
  end

  test "will stop process when unable to write to data file", %{load: load} do
    Persist.TableCreatorMock
    |> stub(:create, fn _, _ -> :ok end)

    Persist.DataFileMock
    |> stub(:open, fn _, _ -> {:ok, :data_file} end)
    |> stub(:write, fn _, _ -> {:error, "failed to write"} end)

    {:ok, pid} = Persist.Writer.DirectUpload.start_link(load: load, dictionary: :dictionary)
    assert {:error, "failed to write"} = Persist.Writer.DirectUpload.write(pid, [:data])
  end

  test "will stop process when unable to upload data file", %{load: load} do
    Persist.TableCreatorMock
    |> stub(:create, fn _, _ -> :ok end)

    Persist.DataFileMock
    |> stub(:open, fn _, _ -> {:ok, :data_file} end)
    |> stub(:write, fn _, _ -> {:ok, 101} end)
    |> stub(:close, fn _ -> "file" end)

    Persist.UploaderMock
    |> stub(:upload, fn _, _ -> {:error, "failed to upload"} end)

    {:ok, pid} = Persist.Writer.DirectUpload.start_link(load: load, dictionary: :dictionary)
    assert {:error, "failed to upload"} = Persist.Writer.DirectUpload.write(pid, [:data])
  end
end
