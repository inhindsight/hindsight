import React from "react"
import {Argument} from "./Argument"
import {ModuleFunctionArgsView} from "../../../../model/view/ModuleFunctionArgsView"

export const ModuleFunctionArgs = (moduleFunctionArgs: ModuleFunctionArgsView) =>
    <>
        <strong>Module</strong>
        <p>{moduleFunctionArgs.struct_module_name}</p>
        <strong>Arguments</strong>
        {moduleFunctionArgs.args.map(argument => <Argument key={argument.key} argument={argument}/>)}
    </>
