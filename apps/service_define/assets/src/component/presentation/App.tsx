import React from "react"
import {ConnectedMessage} from "../connected/ConnectedMessage"
import {StateProvider} from "../../util/connector"
import {ConnectedDataDefinitionList} from "../connected/ConnectedDataDefinitionList"


export const App = () => <StateProvider>
    <ConnectedMessage/>
    <ConnectedDataDefinitionList/>
</StateProvider>

