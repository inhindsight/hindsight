import React from "react"
import {PersistView} from "../../../model/view/DataDefinitionView"


export const Persist = (persist: PersistView) =>
    <div className="card" >
        <div className="card-header bg-success text-white"><strong>Persist</strong></div>
        <div className="card-body">
            <span className="text-muted">source:</span> {persist.source ?? ""}<br/>
            <span className="text-muted">destination:</span> {persist.destination ?? ""}
        </div>
    </div>

