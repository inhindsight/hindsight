import React from "react"
import {Persist} from "./Persist"
import {Extract} from "./Extract"
import {Transform} from "./Transform"
import {DataDefinitionView} from "../../../model/view/DataDefinitionView"

export const DataDefinition = ({dataset_id, subset_id, extract, persist, transform}: DataDefinitionView) =>
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
            <Persist {...persist}/>
        </div>
    </div>
