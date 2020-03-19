import { AppView, ExtractView, PersistView, DataDefinitionView} from './../../model/view'

export const appViewDefaults: AppView = {
    greeting: "",
    data_definitions: [],
}

export const extractViewDefaults: ExtractView = {
    destination: "",
}

export const persistViewDefaults: PersistView = {
    source: "",
    destination: "",
}

export const dataDefinitionDefaults: DataDefinitionView = {
    dataset_id: "",
    subset_id: "",
    extract: extractViewDefaults,
    persist: persistViewDefaults,
}