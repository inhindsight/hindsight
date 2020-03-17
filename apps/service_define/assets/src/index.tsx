import {Socket} from "phoenix"
import ReactDOM from "react-dom"
import {App} from "./component/App"
import React from "react"

ReactDOM.render(
    <App/>,
    document.getElementById("root")
)


const socket = new Socket("/socket")
// tslint:disable-next-line:no-console
socket.onClose(() => console.log(`Socket connection closed`))
socket.connect()

const channel = socket.channel("view_state:main", {})
// tslint:disable-next-line:no-console
channel.on("update", (message) => console.log(message) )
channel.on("phx_reply", resp => { console.log("Joined successfully", resp) })
channel.join()
