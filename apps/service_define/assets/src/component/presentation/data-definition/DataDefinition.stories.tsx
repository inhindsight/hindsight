import {storiesOf} from "@storybook/react"
import React from "react"
import {DataDefinition} from "./DataDefinition"
import {DataDefinitionView} from "../../../model/view/DataDefinitionView"
import { PrimitiveArgumentType } from "../../../model/view/ModuleFunctionArgsView"

const simpleProps: DataDefinitionView = {
    dataset_id: "houses",
    subset_id: "default",
    extract: {
        destination: "gather-topic",
        dictionary: [
            {
                struct_module_name: "Elixir.Dictionary.Type.String",
                args: [ { key: "name", type: PrimitiveArgumentType.string, value: "address" } ]
            },
            {
                struct_module_name: "Elixir.Dictionary.Type.String",
                args: [ { key: "name", type: PrimitiveArgumentType.string, value: "owner_first_name" } ]
            },
            {
                struct_module_name: "Elixir.Dictionary.Type.String",
                args: [ { key: "name", type: PrimitiveArgumentType.string, value: "owner_last_name" } ]
            },
            {
                struct_module_name: "Elixir.Dictionary.Type.Integer",
                args: [ { key: "name", type: PrimitiveArgumentType.integer, value: "square_feet" } ]
            },

        ],
        steps: [
            {
                struct_module_name: "Elixir.Extract.Http.Get",
                args: [ { key: "url", type: PrimitiveArgumentType.integer, value: "http://example.com/api/v1/homes" } ]
            },
        ],
    },
    transform: {
        dictionary: [
            {
                struct_module_name: "Elixir.Dictionary.Type.String",
                args: [ { key: "name", type: PrimitiveArgumentType.string, value: "address" } ]
            },
            {
                struct_module_name: "Elixir.Dictionary.Type.String",
                args: [ { key: "name", type: PrimitiveArgumentType.string, value: "owner_name" } ]
            },
            {
                struct_module_name: "Elixir.Dictionary.Type.Integer",
                args: [ { key: "name", type: PrimitiveArgumentType.integer, value: "square_feet" } ]
            }
        ],
        steps: [
            {
                struct_module_name: "Elixir.Transform.ConcatFields",
                args: [
                    { key: "field_left", type: PrimitiveArgumentType.string, value: "owner_first_name" },
                    { key: "field_right", type: PrimitiveArgumentType.string, value: "owner_last_name" },
                    { key: "new_field_name", type: PrimitiveArgumentType.string, value: "owner_name" }
                ]
            },
        ],
    },
    persist: {
        source: "gathered-topic",
        destination: "houses-table",
    }
}

const nestedProps: DataDefinitionView = {
    ...simpleProps,
    extract: {
        ...simpleProps.extract,
        steps: [
            {
                struct_module_name: "Elixir.Extract.Http.Get",
                args: [
                     { key: "url", type: PrimitiveArgumentType.integer, value: "http://example.com/api/v1/homes" },
                     { key: "headers", type: PrimitiveArgumentType.map, value: {"content-length": "5"} },
                     { key: "alternate_urls", type: ["list", PrimitiveArgumentType.string], value: [
                         "http://east.example.com/api/v1/homes",
                         "http://mirror.example.com/api/v1/homes",
                         "http://backup.example.com/api/v1/homes",
                     ] },
                ]
            },
        ],
        dictionary: [
            {
                struct_module_name: "Elixir.Dictionary.Type.Map",
                args: [
                    { key: "name", type: PrimitiveArgumentType.string, value: "address" },
                    { key: "dictionary", type: PrimitiveArgumentType.module, value: [
                        {
                            struct_module_name: "Elixir.Dictionary.Type.String",
                            args: [ { key: "name", type: PrimitiveArgumentType.string, value: "street_address" } ]
                        },
                        {
                            struct_module_name: "Elixir.Dictionary.Type.String",
                            args: [ { key: "name", type: PrimitiveArgumentType.string, value: "city" } ]
                        },
                        {
                            struct_module_name: "Elixir.Dictionary.Type.String",
                            args: [ { key: "name", type: PrimitiveArgumentType.string, value: "state" } ]
                        },
                        {
                            struct_module_name: "Elixir.Dictionary.Type.Integer",
                            args: [ { key: "name", type: PrimitiveArgumentType.string, value: "zip" } ]
                        },
                    ]}
             ]
            },
            {
                struct_module_name: "Elixir.Dictionary.Type.String",
                args: [ { key: "name", type: PrimitiveArgumentType.string, value: "owner_name" } ]
            }
        ]
    },
    transform: {
        ...simpleProps.transform,
        dictionary: [
            {
                struct_module_name: "Elixir.Dictionary.Type.String",
                args: [ { key: "name", type: PrimitiveArgumentType.string, value: "owner_name" } ]
            },
            {
                struct_module_name: "Elixir.Dictionary.Type.Integer",
                args: [ { key: "name", type: PrimitiveArgumentType.integer, value: "square_feet" } ]
            }
        ],
        steps: [
            {
                struct_module_name: "Elixir.Transform.DropField",
                args: [ { key: "field", type: PrimitiveArgumentType.string, value: "address" } ]
            }
        ]
    }
}

storiesOf("DataDefinition", module)
    .add("simple", () => <DataDefinition {...simpleProps}/>)
    .add("nested", () => <DataDefinition {...nestedProps}/>)
