import { ObjectMap } from "../../../../model/ObjectMap"
import { toPairs } from "ramda"
import React from "react"

export const Map = ({ object }: { readonly object: ObjectMap<any> }) =>
    <div className="card border-info">
        <div className="card-header bg-info text-white">Map</div>
        <ul className="list-group list-group-flush">
            {toPairs(object).map(([key, value]) =>
            <li key={key} className="list-group-item">
                <span className="text-muted">{key}:</span> {value}
            </li>
            )}
        </ul>
    </div>
