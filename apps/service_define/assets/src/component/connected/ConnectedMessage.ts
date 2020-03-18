import { Message } from "../presentation/Message"
import {connect} from "../../util/connector"

export const ConnectedMessage = connect(Message, (state, pushEvent) => ({
    message: state.greeting,
    clicked: (number) => pushEvent({ type: "new_greeting", greeting: number.toString() })
}))
