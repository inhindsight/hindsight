import React from "react"
import {ModuleFunctionArgs} from "./ModuleFunctionArgs"
import {
    ArgumentType,
    isListArgumentType,
    ModuleFunctionArgsView,
    PrimitiveArgumentType
} from "../../../../model/view/ModuleFunctionArgsView"

export type ValueComponent = (props: { readonly value: any }) => any

export const componentForType = (type: ArgumentType): ValueComponent => {
    if(isListArgumentType(type)) {
        const [, genericType] = type
        return ListWrapper(componentForType(genericType))
    } else {
        return type === PrimitiveArgumentType.module ? ModuleFunctionArgsWrapper : StringWrapper
    }
}

export const StringWrapper = ({value}: {readonly value: string}) => <>{value.toString()}</>
export const ModuleFunctionArgsWrapper = ({value}: { readonly value: readonly ModuleFunctionArgsView[]}) => value.map(value => <ModuleFunctionArgs {...value}/>)
export const ListWrapper = (Component: ValueComponent) => ({value}: { readonly value: readonly any[]}) => value.map(value => <Component {...value}/>)
