
export interface AppView {
    readonly greeting: string
    readonly data_definitions: readonly DataDefinitionView[]
}



export interface DataDefinitionView {
    readonly dataset_id: string
    readonly subset_id: string
    readonly dictionary: readonly ModuleFunctionArgsView[]
    readonly extract: ExtractView
    readonly persist: PersistView
}

export interface ExtractView {
    readonly destination: string
    readonly steps: readonly ModuleFunctionArgsView[]
}

export interface PersistView {
    readonly source: string
    readonly destination: string
}


export interface ModuleFunctionArgsView {
    readonly struct_module_name: string
    readonly args: readonly ArgumentView[]
}

export interface ArgumentView {
    readonly key: string
    readonly type: ArgumentType | ListArgumentType
    readonly value: PrimitiveTypes | ObjectMap<PrimitiveTypes> | ReadonlyArray<PrimitiveTypes>
}

export type PrimitiveTypes = string | number | boolean

export enum ArgumentType {
    string = "string",
    integer = "integer",
    atom = "atom",
    float = "float",
    boolean = "boolean",
    module = "module",
}

export type ListArgumentType = readonly ["list", ArgumentType]

export interface ObjectMap<T> {
    readonly [key: string]: T
}



