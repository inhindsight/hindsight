import {Message} from "../presentation/Message"
import {connect} from "../../util/connector"
import {newGreeting} from "../../model/event"

export const ConnectedMessage = connect(Message, (state, pushEvent) => ({
    message: state.greeting,
    clicked: (number) => pushEvent(newGreeting({ greeting: number.toString() }))
}))
