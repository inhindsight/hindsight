defmodule ExtractorTest do
  use ExUnit.Case

  defmodule SourceHandler do
    use Source.Handler

    def handle_message(message, context) do
      send(context.assigns.test, {:handle_message, message})
      {:ok, message}
    end

    def handle_batch(batch, context) do
      send(context.assigns.test, {:handle_batch, batch})
      :ok
    end

    def send_to_dlq(dead_letters, context) do
      send(context.assigns.test, {:dlq, dead_letters})
      :ok
    end
  end

  describe "source" do
    setup do
      test = self()

      after_function = fn list -> send(test, {:after_function, list}) end
      error_function = fn -> send(test, :error_function) end

      steps = [
        %Test.Steps.RegisterFunctions{after: after_function, error: error_function},
        %Test.Steps.CreateResponse{response: %{body: [1, 2, 3, 4, 5, 6]}},
        %Test.Steps.SetStream{},
        %Test.Steps.TransformStream{transform: fn x -> x * 2 end}
      ]

      source = Extractor.new!(steps: steps)

      context =
        Source.Context.new!(
          dictionary: Dictionary.from_list([]),
          handler: SourceHandler,
          app_name: "testing",
          dataset_id: "ds1",
          subset_id: "sb1",
          assigns: %{
            test: self()
          }
        )

      [source: source, context: context]
    end

    test "sends data from extract pipeline to source handler", %{
      source: source,
      context: source_context
    } do
      {:ok, _source} = Source.start_link(source, source_context)

      assert_receive {:handle_message, 2}
      assert_receive {:handle_message, 4}
      assert_receive {:handle_batch, [2, 4]}
      assert_receive {:handle_message, 6}
      assert_receive {:handle_message, 8}
      assert_receive {:handle_batch, [6, 8]}
      assert_receive {:handle_message, 10}
      assert_receive {:handle_message, 12}
      assert_receive {:handle_batch, [10, 12]}
    end

    test "call after function for each batch", %{source: source, context: source_context} do
      {:ok, _source} = Source.start_link(source, source_context)

      assert_receive {:after_function, [%Extract.Message{data: 2}, %Extract.Message{data: 4}]}
      assert_receive {:after_function, [%Extract.Message{data: 6}, %Extract.Message{data: 8}]}
      assert_receive {:after_function, [%Extract.Message{data: 10}, %Extract.Message{data: 12}]}
    end

    test "calls error function if error is raised", %{source: source, context: source_context} do
      new_steps =
        source.steps ++ [%Test.Steps.TransformStream{transform: fn _ -> raise "bad stuff" end}]

      source = %{source | steps: new_steps}

      {:ok, _source} = Source.start_link(source, source_context)

      assert_receive :error_function
    end
  end
end
