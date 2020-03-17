import React from "react"
import { StateProvider } from "../connected/Connector"
import {ConnectedMessage} from "../connected/ConnectedMessage"


export const App = () => <StateProvider>
    <ConnectedMessage/>
</StateProvider>

