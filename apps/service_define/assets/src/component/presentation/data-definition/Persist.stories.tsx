import {storiesOf} from "@storybook/react"
import React from "react"
import {Persist} from "./Persist"
import {PersistView} from "../../../model/view/DataDefinitionView"

const props: PersistView = {
    source: "bus-route-source",
    destination: "bus-route-destination",
}

storiesOf("Persist", module)
    .add("default", () => <Persist {...props}/>)
