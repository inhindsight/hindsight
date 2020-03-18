import {storiesOf} from "@storybook/react"
import {Message, MessageProps} from "./Message"
import React from "react"

const props: MessageProps = {
    message: "Hello world!",
    clicked: () => {}
}

storiesOf("Message", module)
    .add("default", () => <Message {...props}/>)
