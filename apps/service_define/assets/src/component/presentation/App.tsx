import React from "react"
import {StateProvider} from "../../util/connector"
import {ConnectedDataDefinitionList} from "../connected/ConnectedDataDefinitionList"


export const App = () => <StateProvider>
    <div className="container">
        <div className="col">
            <h1>Data Definitions</h1>
            <br/>
            <ConnectedDataDefinitionList/>
        </div>
    </div>
</StateProvider>

