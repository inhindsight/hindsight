import React from "react"
import {LoadView} from "../../../model/view/DataDefinitionView"
import {ModuleFunctionArgs} from "./common/ModuleFunctionArgs"


export const Load = (load: LoadView) =>
    <div className="card" >
        <div className="card-header bg-success text-white"><strong>Load</strong></div>
        <div className="card-body">
            <ModuleFunctionArgs {...load.source} /><br/>
            <span className="text-muted">destination:</span><br/>
            <ModuleFunctionArgs {...load.destination} /><br/>
        </div>
    </div>

