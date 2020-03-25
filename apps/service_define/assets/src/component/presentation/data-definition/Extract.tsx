import React from "react"
import {ExtractView} from "../../../model/view"
import {ModuleFunctionArgs} from "./module-function-args/ModuleFunctionArgs"

export const Extract = (extract: ExtractView) => <>
    <div className="form-group">
        <label>Source</label>
        <input type="text" className="form-control" value={extract.destination ?? ""} />

    </div>
    <p>Dictionary</p>
    {/* TODO: Remove JSON key */}
    {extract.dictionary.map(dictionary => <ModuleFunctionArgs key={JSON.stringify(dictionary)} {...dictionary} />)}
</>
