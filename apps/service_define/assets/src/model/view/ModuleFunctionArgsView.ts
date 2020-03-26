import {isArray} from "lodash"
import {ObjectMap} from "../ObjectMap"

export interface ModuleFunctionArgsView {
    readonly struct_module_name: string
    readonly args: readonly ArgumentView[]
}

export interface ArgumentView {
    readonly key: string
    readonly type: ArgumentType
    readonly value: ArgumentValue | ObjectMap<ArgumentValue> | ReadonlyArray<ArgumentValue>
}

export type ArgumentValue = PrimitiveTypes | ModuleFunctionArgsView
export type PrimitiveTypes = string | number | boolean

export type ArgumentType = PrimitiveArgumentType | ListArgumentType
export enum PrimitiveArgumentType {
    string = "string",
    integer = "integer",
    atom = "atom",
    float = "float",
    boolean = "boolean",
    module = "module",
    map = "map",
}

export type ListArgumentType = readonly ["list", ArgumentType]
export const isListArgumentType = (type: ArgumentType): type is ListArgumentType => isArray(type) && type[0] === "list"
