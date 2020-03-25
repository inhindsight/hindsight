import { connect } from '../../util/connector'
import {DataDefinitionList} from "../presentation/data-definition/DataDefinitionList"

export const ConnectedDataDefinitionList = connect(DataDefinitionList, (state, pushEvent) => ({
    definitions: state.data_definitions,
}))
