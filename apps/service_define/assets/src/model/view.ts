export interface AppView {
    readonly greeting: string
    readonly data_definitions: readonly DataDefinitionView[]
}

export interface DataDefinitionView {
    readonly dataset_id: string
    readonly subset_id: string
    readonly extract: ExtractView
    readonly persist: PersistView
}

export interface ExtractView {
    readonly destination: string
    readonly steps: readonly DefinitionView[]
}

export interface PersistView {
    readonly source: string
    readonly destination: string
}

export interface DefinitionView {
    readonly struct_module_name: string | null
    readonly fields: readonly FieldView[]
}


export interface FieldView {
    readonly key: string
    readonly type: InputType | DefinitionView
    readonly value: any
}

export enum InputType {
    text = "text",
    boolean = "boolean"
}





