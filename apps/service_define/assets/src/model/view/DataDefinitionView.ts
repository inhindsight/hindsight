import {ModuleFunctionArgsView} from "./ModuleFunctionArgsView"

export interface DataDefinitionView {
    readonly dataset_id: string
    readonly subset_id: string
    readonly extract: ExtractView
    readonly persist: PersistView
    readonly transform: TransformView
}

export interface TransformView {
    readonly dictionary: readonly ModuleFunctionArgsView[]
    readonly steps: readonly ModuleFunctionArgsView[]
}

export interface ExtractView {
    readonly destination: string | null
    readonly dictionary: readonly ModuleFunctionArgsView[]
    readonly steps: readonly ModuleFunctionArgsView[]
}

export interface PersistView {
    readonly source: string | null
    readonly destination: string | null
}
