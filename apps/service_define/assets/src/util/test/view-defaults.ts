import {AppView} from "../../model/view/AppView"
import {DataDefinitionView, ExtractView, PersistView, TransformView} from "../../model/view/DataDefinitionView"
import { ModuleFunctionArgsView, ArgumentView, PrimitiveArgumentType } from '../../model/view/ModuleFunctionArgsView'

export const appViewDefaults: AppView = {
    greeting: "",
    data_definitions: [],
}

export const extractViewDefaults: ExtractView = {
    destination: "",
    dictionary: [],
    steps: [],
}

export const transformViewDefaults: TransformView = {
    dictionary: [],
    steps: [],
}

export const persistViewDefaults: PersistView = {
    source: "",
    destination: "",
}


export const dataDefinitionDefaults: DataDefinitionView = {
    dataset_id: "",
    subset_id: "",
    extract: extractViewDefaults,
    transform: transformViewDefaults,
    persist: persistViewDefaults,
}

export const moduleFunctionArgsViewDefaults: ModuleFunctionArgsView = {
    struct_module_name: "",
    args: []
}

export const argumentDefaults: ArgumentView = {
    key: "",
    type: PrimitiveArgumentType.string,
    value: "",
}
