import {DataDefinitionView} from "./DataDefinitionView"

export interface AppView {
    readonly greeting: string
    readonly data_definitions: readonly DataDefinitionView[]
}

