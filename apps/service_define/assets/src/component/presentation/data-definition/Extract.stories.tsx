import {storiesOf} from "@storybook/react"
import React from "react"
import {Extract} from "./Extract"
import {ExtractView} from "../../../model/view/DataDefinitionView"
import {PrimitiveArgumentType} from "../../../model/view/ModuleFunctionArgsView"

const props: ExtractView = {
    destination: "bus-route-destination",
    dictionary: [
        {
            struct_module_name: "Elixir.Dictionary.Type.String",
            args: [
                {
                    key: "name",
                    type: PrimitiveArgumentType.string,
                    value: "person"
                }
            ]
        },
        {
            struct_module_name: "Elixir.Dictionary.Type.Map",
            args: [
                {
                    key: "name",
                    type: PrimitiveArgumentType.string,
                    value: "person"
                },
                {
                    key: "dictionary",
                    type: PrimitiveArgumentType.module,
                    value: [
                        {
                            struct_module_name: "Elixir.Dictionary.Type.String",
                            args: [
                                {
                                    key: "name",
                                    type: PrimitiveArgumentType.string,
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
