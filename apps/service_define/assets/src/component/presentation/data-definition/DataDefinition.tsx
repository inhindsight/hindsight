import React from "react"
import {Extract} from "./Extract"
import {Transform} from "./Transform"
import {DataDefinitionView} from "../../../model/view/DataDefinitionView"
import {Load} from "./Load"

export const DataDefinition = ({dataset_id, subset_id, extract, load, transform}: DataDefinitionView) =>
    <div className="card border-secondary">
        <div className="card-header bg-secondary text-white"><strong>Dataset</strong></div>
        <div className="card-body">
            <p>
                <span className="text-muted">id:</span> {dataset_id}<br/>
                <span className="text-muted">subset id:</span> {subset_id}
            </p>

            <Extract {...extract}/>
            <br/>
            <Transform {...transform}/>
            <br/>
            <Load {...load}/>
        </div>
    </div>
