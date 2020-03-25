import React from "react"
import {Persist} from "./Persist"
import {Extract} from "./Extract"
import {DataDefinitionView} from "../../../model/view"

export const DataDefinition = ({dataset_id, subset_id, extract, persist}: DataDefinitionView) =>
    <>
        <h2> Data Definition</h2>
        <div className="form-group">
            <label>Dataset ID</label>
            <input type="text" className="form-control" value={dataset_id} />
            <label>Subset ID</label>
            <input type="text" className="form-control" value={subset_id} />
        </div>

        <h4>Extract</h4>
        <Extract {...extract}/>

        <h4>Persist</h4>
        <Persist {...persist}/>
    </>
