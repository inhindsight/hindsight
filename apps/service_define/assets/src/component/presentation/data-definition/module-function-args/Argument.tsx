import React from "react"
import {componentForType} from "./componentForType"
import {ArgumentView} from "../../../../model/view/ModuleFunctionArgsView"

export interface ArgumentProps {
    readonly argument: ArgumentView
}

export const Argument = ({ argument: {key, value, type}}: ArgumentProps) => {
    const ComponentForType = componentForType(type)

    return <p>
      Key: {key}<br/>
      Type: {type}<br/>
      Value: <ComponentForType value={value}/>
    </p>
}
