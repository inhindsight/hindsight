export interface AppView {
    readonly greeting: string
    readonly data_definitions: readonly DataDefinitionView[]
}

export interface DataDefinitionView {
    readonly dataset_id: string
    readonly subset_id: string
    // readonly dictionary: readonly Dictionary[]
    readonly extract: ExtractView
    readonly persist: PersistView
}

export interface ExtractView {
    readonly destination: string
    // readonly steps: readonly StepView[]
}

export interface PersistView {
    readonly source: string
    readonly destination: string
    // readonly steps: readonly StepView[]
}

// export interface StepView {
//     readonly module: string
//     readonly params: ObjectMap<string>
// }

// interface ObjectMap<T> { readonly [key: string]: T }

// // interface Dictionary {
// //     readonly name: string,
// //     readonly description: string,
// // }

// // interface Date extends Dictionary {
// //     readonly format: string
// // }

// // type ItemType = string | Float | Dictionary | List | FooMap

// // interface List {
// //     readonly item_type: ItemType
// // }

// // interface FooMap {
// //     readonly dictionary: readonly Dictionary[]
// // }


interface SchemaView {
    readonly name: string
    readonly fields: readonly FieldView[]
}

interface FieldView {
    readonly field_name: string
    readonly type: PrimitiveType | ListView | SchemaView
}

interface ListView {
    readonly type: PrimitiveType | ListView | SchemaView
}

enum PrimitiveType {
    text = "text",
    boolean = "boolean"
}
