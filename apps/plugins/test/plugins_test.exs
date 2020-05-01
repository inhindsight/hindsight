defmodule PluginsTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  require Temp.Env

  describe "with valid plugins" do
    Temp.Env.modify([%{app: :plugins, key: Plugins, set: [source_dir: "test/plugins/good"]}])

    test "load!/0 compiles and loads plugin modules" do
      log = capture_log([level: :info], fn -> Plugins.load!() end)

      assert Code.ensure_loaded?(FirstPlugin)
      assert Code.ensure_loaded?(SecondPlugin)
      assert Code.ensure_loaded?(ThirdPlugin)

      assert log =~ "Loaded 2 plugin files"
    end
  end

  describe "with non-existent source directory" do
    Temp.Env.modify([%{app: :plugins, key: Plugins, set: [source_dir: "test/plugins/noop"]}])

    test "load!/0 compiles and loads no plugins" do
      log = capture_log([level: :info], fn -> Plugins.load!() end)
      assert log =~ "Loaded 0 plugin files"
    end
  end

  describe "with empty source directory" do
    Temp.Env.modify([%{app: :plugins, key: Plugins, set: [source_dir: "test/plugins/empty"]}])

    test "load!/0 compiles and loads no plugins" do
      log = capture_log([level: :info], fn -> Plugins.load!() end)
      assert log =~ "Loaded 0 plugin files"
    end
  end

  describe "with invalid plugins" do
    Temp.Env.modify([%{app: :plugins, key: Plugins, set: [source_dir: "test/plugins/bad"]}])

    test "load!/0 raises an exception" do
      log =
        capture_log([level: :error], fn ->
          assert_raise Plugins.PluginError, fn -> Plugins.load!() end
        end)

      assert log =~ "Failed to load plugin file"
    end
  end
end
