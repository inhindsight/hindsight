import {storiesOf} from "@storybook/react"
import React from "react"
import {Extract} from "./Extract"
import {ArgumentType, ExtractView} from "../../../model/view"

const props: ExtractView = {
    destination: "bus-route-destination",
    dictionary: [
        {
            struct_module_name: "Elixir.Dictionary.Type.String",
            args: [
                {
                    key: "name",
                    type: ArgumentType.string,
                    value: "person"
                }
            ]
        },
        {
            struct_module_name: "Elixir.Dictionary.Type.Map",
            args: [
                {
                    key: "name",
                    type: ArgumentType.string,
                    value: "person"
                },
                {
                    key: "dictionary",
                    type: ArgumentType.module,
                    value: [
                        {
                            struct_module_name: "Elixir.Dictionary.Type.String",
                            args: [
                                {
                                    key: "name",
                                    type: ArgumentType.string,
                                    value: "name"
                                }
                            ]
                        }
                    ]
                }
            ]
        }
    ],
    steps: [],
}

storiesOf("Extract", module)
    .add("default", () => <Extract {...props}/>)
