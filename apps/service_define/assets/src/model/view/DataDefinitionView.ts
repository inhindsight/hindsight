import {ModuleFunctionArgsView} from "./ModuleFunctionArgsView"

export interface DataDefinitionView {
    readonly dataset_id: string
    readonly subset_id: string
    readonly extract: ExtractView
    readonly load: LoadView
    readonly transform: TransformView
}

export interface TransformView {
    readonly dictionary: readonly ModuleFunctionArgsView[]
    readonly steps: readonly ModuleFunctionArgsView[]
}

export interface ExtractView {
    readonly dictionary: readonly ModuleFunctionArgsView[]
    readonly source: ModuleFunctionArgsView
    readonly destination: ModuleFunctionArgsView
    readonly decoder: ModuleFunctionArgsView
}

export interface LoadView {
    readonly source: ModuleFunctionArgsView
    readonly destination: ModuleFunctionArgsView
}
