import {storiesOf} from "@storybook/react"
import React from "react"
import {Transform} from "./Transform"
import {TransformView} from "../../../model/view"

const props: TransformView = {
    dictionary: [],
    steps: [],
}

storiesOf("Transform", module)
    .add("default", () => <Transform {...props}/>)
