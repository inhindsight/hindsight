import {storiesOf} from "@storybook/react"
import React from "react"
import {DataDefinition} from "./DataDefinition"
import {DataDefinitionView} from "../../../model/view/DataDefinitionView"
import {PrimitiveArgumentType} from "../../../model/view/ModuleFunctionArgsView"

const simpleProps: DataDefinitionView = {
    dataset_id: "houses",
    subset_id: "default",
    extract: {
        source: {
            struct_module_name: "Elixir.Extractor",
            args: [
                {
                    key: "steps",
                    type: ["list", PrimitiveArgumentType.module],
                    value: [
                        {
                            struct_module_name: "Extract.Http.Get",
                            args: [
                                { key: "url", type: PrimitiveArgumentType.string, value: "http://www.example.com/the-data.csv"}
                            ]
                        }
                    ]
                }

            ]
        },
        destination: {
            struct_module_name: "Elixir.Kafka.Topic",
            args: [
                { key: "name", type: PrimitiveArgumentType.string, value: "csv-gather"},
                { key: "endpoints", type: PrimitiveArgumentType.map, value: { host: 9092 }},
            ]
        },
        decoder: {
            struct_module_name: "Elixir.Decoder.Csv",
            args: [
                {
                    key: "headers",
                    type: ["list", PrimitiveArgumentType.string],
                    value: ["address", "owner_first_name", "owner_last_name", "square_feet"]
                },
                {
                    key: "skip_first_line",
                    type: PrimitiveArgumentType.boolean,
                    value: true
                }
            ]
        },
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
    load: {
        source: {
            struct_module_name: "Elixir.Kafka.Topic",
            args: [
                { key: "name", type: PrimitiveArgumentType.string, value: "csv-gather"},
                { key: "endpoints", type: PrimitiveArgumentType.map, value: { host: 9092 }},
            ]
        },
        destination: {
            struct_module_name: "Elixir.Presto.Table",
            args: [
                { key: "url", type: PrimitiveArgumentType.string, value: "http://localhost:8080"},
                { key: "name", type: PrimitiveArgumentType.string, value: "csv-table"},
            ]
        },
    }
}

const nestedProps: DataDefinitionView = {
    ...simpleProps,
    extract: {
        ...simpleProps.extract,
        source: {
            struct_module_name: "Elixir.Extractor",
            args: [
                {
                    key: "steps",
                    type: ["list", PrimitiveArgumentType.module],
                    value: [
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
                }

            ]
        },
        dictionary: [
            {
                struct_module_name: "Elixir.Dictionary.Type.Map",
                args: [
                    { key: "name", type: PrimitiveArgumentType.string, value: "address" },
                    { key: "dictionary", type: ["list", PrimitiveArgumentType.module], value: [
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
            },
            {
                struct_module_name: "Elixir.Dictionary.Type.List",
                args: [
                    { key: "name", type: PrimitiveArgumentType.string, value: "features" },
                    { key: "item_type",
                      type: PrimitiveArgumentType.module,
                      value: {
                          struct_module_name: "Elixir.Dictionary.Type.Map",
                          args: [
                              { key: "name", type: PrimitiveArgumentType.string, value: "feature" },
                              { key: "dictionary",
                                type: ["list", PrimitiveArgumentType.module],
                                value: [
                                  {struct_module_name: "Elixir.Dictionary.Type.Integer",
                                   args: [{key: "name", type: PrimitiveArgumentType.string, value: "num_of_bedrooms" }]
                                  },
                                  {struct_module_name: "Elixir.Dictionary.Type.Integer",
                                   args: [{key: "name", type: PrimitiveArgumentType.string, value: "num_of_bathrooms" }]
                                  }
                                ]
                              }
                          ]
                      }
                    }
                ]
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
