export interface AppView {
    readonly greeting: string
    // readonly edit_dataset_definition: DataDefinitionView
}
    // dataset_id: String.t(),
    // subset_id: String.t(),
    // dictionary: map,
    // extract_destination: String.t(),
    // extract_steps: list,
    // transform_steps: list,
    // persist_source: String.t(),
    // persist_destination: String.t()

//
// export interface DataDefinitionView {
//     readonly dataset_id: string
//     readonly subset_id: string
//     readonly dictionary: readonly Dictionary[]
//     readonly extract: ExtractView
//     readonly persist: PersistView
// }
//
// export interface ExtractView {
//     readonly destination: string
//     readonly steps: readonly StepView[]
// }
//
// export interface PersistView {
//     readonly source: string
//     readonly destination: string
//     readonly steps: readonly StepView[]
// }

// export interface StepView {
//     readonly module: string
//     readonly params: ObjectMap<string>
// }
//
// interface ObjectMap<T> { readonly [key: string]: T }
//
// interface Dictionary {
//     readonly name: string,
//     readonly description: string,
// }
//
// interface Date extends Dictionary {
//     readonly format: string
// }
//
// type ItemType = string | Float | Dictionary | List | FooMap
//
// interface List {
//     readonly item_type: ItemType
// }
//
// interface FooMap {
//     readonly dictionary: readonly Dictionary[]
// }
//
//
// interface Schema {
//     name: string
//     fields: Field[]
// }
//
// interface Field {
//     field_name: string
//     type: PrimitiveType | List | Schema
// }
//
// interface List {
//     type: PrimitiveType | List | Schema
// }
//
// enum PrimitiveType {
//     text = "text",
//     boolean = "boolean"
// }

// headers: :list

//       Extract.Decode.Csv => [headers: :list, skip_first_line: :boolean],
//       Extract.Decode.Json => [],
// Extract.Decode.Csv.new!(%{headers, skipejaslkfjas})
// apply(module, func, args)


    // %{
    //   Extract.Decode.Csv => [headers: :list, skip_first_line: :boolean],
    //   Extract.Decode.Json => [],
    //   # Headers should be a map of strings
    //   Extract.Http.Get => [url: :string, headers: :string]
    // }
