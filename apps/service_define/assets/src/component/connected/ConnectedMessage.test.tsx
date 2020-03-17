import {queryByTestHandle, renderComponentWithState} from "../../util/test/container-testing"
import {ConnectedMessage} from "./ConnectedMessage"
import {trigger} from "dom-sim"
import {expect} from "chai"
import React from "react"
import {MessageTestHandles} from "../presentation/Message"

describe("ConnectedMessage", () => {

    it("when the message is clicked fires a greeting updated event", () => {
        const {rootElement, pushedEvents} = renderComponentWithState(<ConnectedMessage/>)

        trigger(queryByTestHandle(MessageTestHandles.Message, rootElement), "click")

        const events = pushedEvents()
        expect(events).to.have.length(1)
        expect(events[0].type).to.equal("new_greeting")
        expect(Number(events[0].greeting)).to.be.greaterThan(0)
    })

})

