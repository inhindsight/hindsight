import React from "react"
import {ConnectedMessage} from "../connected/ConnectedMessage"
import {StateProvider} from "../../util/connector"


export const App = () => <StateProvider>
    <ConnectedMessage/>
</StateProvider>

