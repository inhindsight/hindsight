import React from "react"
import {ModuleFunctionArgs} from "./module-function-args/ModuleFunctionArgs"
import {ExtractView} from "../../../model/view/DataDefinitionView"

export const Extract = (extract: ExtractView) =>
    <div className="card" >
        <div className="card-header bg-success text-white"><strong>Extract</strong></div>
        <div className="card-body">
            <span className="text-muted">source:</span> {extract.destination ?? ""}<br/>
            <span className="text-muted">dictionary:</span><br/>
            {extract.dictionary.map((dictionary, index) => <span key={index}><ModuleFunctionArgs {...dictionary} /><br/></span>)}
            <span className="text-muted">steps:</span><br/>
            {extract.steps.map((step, index) => <span key={index}><ModuleFunctionArgs  {...step} /><br/></span>)}
        </div>
    </div>
