import React from "react"
import {componentForType} from "./componentForType"
import {ArgumentView} from "../../../../model/view/ModuleFunctionArgsView"

export interface ArgumentProps {
    readonly argument: ArgumentView
}

export const Argument = ({ argument: {key, value, type}}: ArgumentProps) => {
    const ComponentForType = componentForType(type)
    return <ul className="list-group list-group-flush">
        <li className="list-group-item">
            <span className="text-muted">{key}:</span> <ComponentForType value={value}/>
        </li>
    </ul>

}
