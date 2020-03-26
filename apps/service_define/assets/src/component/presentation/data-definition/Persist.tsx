import React from "react"
import {PersistView} from "../../../model/view/DataDefinitionView"


export const Persist = (persist: PersistView) =>
<div className="form-group">
    <label>Source</label>
    <input type="text" className="form-control" value={persist.source ?? ""} />
    <label>Destination</label>
    <input type="text" className="form-control" value={persist.destination ?? ""} />
</div>
