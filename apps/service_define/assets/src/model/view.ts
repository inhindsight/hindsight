
export interface AppView {
    readonly greeting: string
    readonly data_definitions: readonly DataDefinitionView[]
}



export interface DataDefinitionView {
    readonly dataset_id: string
    readonly subset_id: string
    readonly dictionary: readonly DictionaryView[]
    readonly extract: ExtractView
    readonly persist: PersistView
}

export interface ExtractView {
    readonly destination: string
    readonly steps: readonly StepView[]
}

export interface PersistView {
    readonly source: string
    readonly destination: string
}




export interface DictionaryView {
    readonly struct_module_name: string
    readonly fields: readonly DictionaryFieldView[]
}

export interface DictionaryFieldView {
    readonly key: string
    readonly type: DictionaryInputType | DictionaryView
}

export enum DictionaryInputType {
    text = "text",
    boolean = "boolean",
}




export interface StepView {
    readonly struct_module_name: string | null
    readonly fields: readonly StepFieldView[]
}

export interface StepFieldView {
    readonly key: string
    readonly type: StepInputType
    readonly value: any
}

export enum StepInputType {
    text = "text",
    boolean = "boolean",
    map = "map",
}




