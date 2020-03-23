defmodule Define.Store do
  require Logger
  alias Define.{StepView, StepFieldView, DictionaryView, DictionaryFieldView, TypespecAnalysis}

  @instance Define.Application.instance()
  @collection "definitions"

  def update_definition(%Extract{} = data) do
    new_dict =
      Enum.map(data.dictionary.ordered, fn value ->
        %DictionaryView{
          struct_module_name: to_string(value.__struct__),
          fields: [
            %DictionaryFieldView{
              key: "name",
              type: value.name
            }
          ]
        }
      end)

    get(data.dataset_id)
    |> Map.put(:dataset_id, data.dataset_id)
    |> Map.put(:subset_id, data.subset_id)
    |> put_in_better([:extract, :destination], data.destination)
    |> put_in_better([:extract, :steps], Enum.map(data.steps, &serialize_step/1))
    |> Map.put(:dictionary, new_dict)
    |> persist()
  end

  def put_in_better(map, [hd], value) do
    Map.put(map, hd, value)
  end

  # TODO Move to utilities
  def put_in_better(map, [hd | tail], value) do
    next_value = Map.get(map, hd)
    Map.put(map, hd, put_in_better(next_value, tail, value))
  end


  # TODO Move out to a module and test by itself
  defp serialize_step(step) do
    struct = step.__struct__
    types = TypespecAnalysis.get_types(struct)
    new_fields = Enum.map(types, fn {k, v} -> %StepFieldView{key: k, type: v, value: Map.get(step, k)} end)

    %StepView{struct_module_name: to_string(struct), fields: new_fields}
  end

  def update_definition(%Transform{} = data) do
    get(data.dataset_id)
    |> Map.put(:dataset_id, data.dataset_id)
    |> Map.put(:subset_id, data.subset_id)
    |> Map.put(:dictionary, data.dictionary)
    |> Map.put(:transform_steps, data.steps)
    |> persist()
  end

  def update_definition(%Load.Persist{} = data) do
    get(data.dataset_id)
    |> Map.put(:dataset_id, data.dataset_id)
    |> Map.put(:subset_id, data.subset_id)
    |> Map.put(:persist_source, data.source)
    |> Map.put(:persist_destination, data.destination)
    |> persist()
  end

  def update_definition(data) do
    Logger.error("Got unexpected data definition update: #{inspect(data)}")
  end

  def get(dataset_id) do
    case Brook.get!(@instance, @collection, dataset_id) do
      nil -> %Define.DataDefinitionView{} |> IO.inspect(label: "The after times")
      map -> map
    end
  end

  def delete_all_definitions() do
    Brook.Test.clear_view_state(@instance, @collection)
  end

  defp persist(data) do
    Brook.ViewState.merge(@collection, data.dataset_id, data)
  end
end
