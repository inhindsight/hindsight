import {storiesOf} from "@storybook/react"
import React from "react"
import {DataDefinition} from "./DataDefinition"
import {DataDefinitionView} from "../../model/view"

const props: DataDefinitionView = {
    dataset_id: "ABC123",
    subset_id: "XYZ789",
    extract: {
        destination: "Hell"
    },
    persist: {
        source: "Hell",
        destination: "Heaven",
    }

}

storiesOf("DataDefinition", module)
    .add("default", () => <DataDefinition {...props}/>)