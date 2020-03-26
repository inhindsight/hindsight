import React from "react"
import { DataDefinition } from "./DataDefinition"
import {DataDefinitionView} from "../../../model/view/DataDefinitionView"

export interface DataDefinitionListProps {
    readonly definitions: readonly DataDefinitionView[]
}

export const DataDefinitionList = ({definitions}: DataDefinitionListProps) =>
    <>
        {definitions.map((definition, index) => <span key={index}><DataDefinition {...definition}/><br/></span>)}
    </>
