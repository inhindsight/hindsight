import {AppView} from "../../model/view/AppView"
import {DataDefinitionView, ExtractView, LoadView, TransformView} from "../../model/view/DataDefinitionView"
import { ModuleFunctionArgsView, ArgumentView, PrimitiveArgumentType } from '../../model/view/ModuleFunctionArgsView'

export const moduleFunctionArgsViewDefaults: ModuleFunctionArgsView = {
    struct_module_name: "",
    args: []
}

export const argumentDefaults: ArgumentView = {
    key: "",
    type: PrimitiveArgumentType.string,
    value: "",
}

export const appViewDefaults: AppView = {
    greeting: "",
    data_definitions: [],
}

export const extractViewDefaults: ExtractView = {
    source: moduleFunctionArgsViewDefaults,
    destination: moduleFunctionArgsViewDefaults,
    decoder: moduleFunctionArgsViewDefaults,
    dictionary: [],
}

export const transformViewDefaults: TransformView = {
    dictionary: [],
    steps: [],
}

export const loadViewDefaults: LoadView = {
    source: moduleFunctionArgsViewDefaults,
    destination: moduleFunctionArgsViewDefaults,
}


export const dataDefinitionDefaults: DataDefinitionView = {
    dataset_id: "",
    subset_id: "",
    extract: extractViewDefaults,
    transform: transformViewDefaults,
    load: loadViewDefaults,
}

