import React from "react"

export const List = ({ list }: { readonly list: readonly any[] }) =>
    <div className="card border-info">
        <div className="card-header bg-info text-white">List</div>
        <ul className="list-group list-group-flush">
            {list.map((value, index) =><li key={index} className="list-group-item">{value}</li>)}
        </ul>
    </div>
