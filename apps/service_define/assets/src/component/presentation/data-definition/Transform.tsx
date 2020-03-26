import React from "react"
import {TransformView} from "../../../model/view/DataDefinitionView"
import { ModuleFunctionArgs } from "./common/ModuleFunctionArgs"

export const Transform = (transform: TransformView) =>
<div className="card" >
    <div className="card-header bg-success text-white"><strong>Transform</strong></div>
    <div className="card-body">
        <span className="text-muted">dictionary:</span><br/>
        {transform.dictionary.map((dictionary, index) => <span key={index}><ModuleFunctionArgs key={index} {...dictionary} /><br/></span>)}
        <span className="text-muted">steps:</span><br/>
        {transform.steps.map((dictionary, index) => <span key={index}><ModuleFunctionArgs key={index} {...dictionary} /><br/></span>)}
    </div>
</div>
