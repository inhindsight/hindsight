import React from "react"
import { DataDefinitionView } from "../../model/AppView"

export const DataDefinition = ({dataset_id, subset_id, extract, persist}: DataDefinitionView) =>
    <div>
        <label>Dataset ID</label>
        <input type="text" value={dataset_id} />
        <label>Subset ID</label>
        <input type="text" value={dataset_id} />
    </div>
