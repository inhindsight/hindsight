import React from "react"
import {Argument} from "./Argument"
import {ModuleFunctionArgsView} from "../../../../model/view/ModuleFunctionArgsView"

export const ModuleFunctionArgs = (moduleFunctionArgs: ModuleFunctionArgsView) =>
    <div className="card border-info">
        <div className="card-header bg-info text-white">{moduleFunctionArgs.struct_module_name}</div>
            {moduleFunctionArgs.args.map(argument => <Argument key={argument.key} argument={argument}/>)}
    </div>
