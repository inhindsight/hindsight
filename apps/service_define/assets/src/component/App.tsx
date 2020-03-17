import React from "react"
import { connect, StateProvider } from "./Connector"



export const App = () => <StateProvider>
    <ConnectedMessage/>
</StateProvider>


const Message = ({message, clicked}: {readonly message: string, readonly clicked: (number: number) => void}) =>
    <h1 onClick={() => clicked(Math.random()) }>
        {message}
    </h1>

const ConnectedMessage = connect(Message, (state, pushEvent) => ({
    message: state.greeting,
    clicked: (number) => pushEvent({ type: "new_greeting", greeting: number.toString() })
}))