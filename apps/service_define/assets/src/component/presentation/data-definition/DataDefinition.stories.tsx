import {storiesOf} from "@storybook/react"
import React from "react"
import {DataDefinition} from "./DataDefinition"
import {DataDefinitionView} from "../../../model/view/DataDefinitionView"

const props: DataDefinitionView = {
    dataset_id: "ABC123",
    subset_id: "XYZ789",
    extract: {
        dictionary: [],
        destination: "Hell",
        steps: [],
    },
    transform: {
        dictionary: [],
        steps: [],
    },
    persist: {
        source: "Hell",
        destination: "Heaven",
    }

}

storiesOf("DataDefinition", module)
    .add("default", () => <DataDefinition {...props}/>)
