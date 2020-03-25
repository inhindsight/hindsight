import React from "react"
import {ArgumentView, ModuleFunctionArgsView} from "../../../../model/view"
import {ModuleFunctionArgs} from "./ModuleFunctionArgs"
import {isArray} from "lodash"

export interface ArgumentProps {
    readonly argument: ArgumentView
}

export const Argument = ({ argument: {key, value, type}}: ArgumentProps) =>
    <p>
      Key: {key}<br/>
      Type: {type}<br/>
      Value: {
        isModuleFunctionArgsView(value) ? value.map(value => <ModuleFunctionArgs {...value} />) : value
    }
    </p>


const isModuleFunctionArgsView = (value: any): value is ModuleFunctionArgsView[] => {
    return isArray(value)
}
