import React from "react"
import { DataDefinition } from "./DataDefinition"
import {DataDefinitionView} from "../../../model/view"

export interface DataDefinitionListProps {
    readonly definitions: readonly DataDefinitionView[]
}

export const DataDefinitionList = ({definitions}: DataDefinitionListProps) =>
    <>
        {definitions.map(definition => <DataDefinition {...definition}/>)}
    </>
