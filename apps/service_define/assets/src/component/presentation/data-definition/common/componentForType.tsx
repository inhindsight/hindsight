import React from "react"
import {ModuleFunctionArgs} from "./ModuleFunctionArgs"
import {
    ArgumentType,
    isListArgumentType,
    ModuleFunctionArgsView,
    PrimitiveArgumentType
} from "../../../../model/view/ModuleFunctionArgsView"
import {Map} from "./Map"
import {List} from "./List"
import { ObjectMap } from "../../../../model/ObjectMap"

export type ValueComponent<T> = (props: { readonly value: T }) => JSX.Element

export const componentForType = (type: ArgumentType): ValueComponent<any> => {
    if(isListArgumentType(type)) {
        const [, subtype] = type
        switch (subtype) {
            case PrimitiveArgumentType.string: return ListWrapper
            case PrimitiveArgumentType.module: return ModuleFunctionArgsListWrapper
            default: return StringWrapper
        }
    } else {
        switch (type) {
            case PrimitiveArgumentType.module: return ModuleFunctionArgsWrapper
            case PrimitiveArgumentType.map: return MapWrapper
            default: return StringWrapper
        }
    }
}

const StringWrapper: ValueComponent<string> =
    ({value}) => <>{value ? value.toString() : "null"}</>

const ModuleFunctionArgsWrapper: ValueComponent<ModuleFunctionArgsView> =
    ({value}) => <ModuleFunctionArgs{...value}/>

const ModuleFunctionArgsListWrapper: ValueComponent<readonly ModuleFunctionArgsView[]> = ({value}) =>
    <>
        {value.map((value, index) => <span key={index}><ModuleFunctionArgs{...value}/><br/></span>)}
    </>

const MapWrapper: ValueComponent<ObjectMap<string>> =
    ({value}) => <Map object={value}/>

const ListWrapper: ValueComponent<readonly string[]> =
    ({value}) => <List list={value}/>
