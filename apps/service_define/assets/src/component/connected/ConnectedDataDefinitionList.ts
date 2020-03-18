import { DataDefinitionList } from './../presentation/DataDefinitionList'
import { connect } from './../../util/connector'

export const ConnectedDataDefinitionList = connect(DataDefinitionList, (state, pushEvent) => ({
    definitions: state.data_definitions,
}))
