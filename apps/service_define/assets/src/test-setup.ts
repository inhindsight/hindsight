import {JSDOM} from "jsdom"
import {defaultsDeep} from "lodash"

const window = new JSDOM("<!doctype html><html><body></body></html>", { url: "http://localhost"}).window
defaultsDeep(global as any, window)
// @ts-ignore
global.Event = window.Event
