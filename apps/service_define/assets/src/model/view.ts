
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
    readonly type: DictionaryFieldType | DictionaryView
}

export enum DictionaryFieldType {
    string = "string",
    boolean = "boolean",
}




export interface StepView {
    readonly struct_module_name: string | null
    readonly fields: readonly StepFieldView[]
}

export interface StepFieldView {
    readonly key: string
    readonly type: StepFieldType | StepListType
    //TODO: Nail down this type more
    readonly value: string | boolean | ObjectMap<any> | ReadonlyArray<any>
}

export enum StepFieldType {
    string = "string",
    boolean = "boolean",
    map = "map",
}

type StepListType = readonly [string, string]


export interface ObjectMap<T> {
    readonly [key: string]: T
}



