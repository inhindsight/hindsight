import { connect } from "./Connector"
import { Message } from "../presentation/Message"

export const ConnectedMessage = connect(Message, (state, pushEvent) => ({
    message: state.greeting,
    clicked: (number) => pushEvent({ type: "new_greeting", greeting: number.toString() })
}))