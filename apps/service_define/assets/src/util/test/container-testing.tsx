import React, {PropsWithChildren} from "react"
import ReactDOM from "react-dom"
import {AppView} from "../../model/AppView"
import {AppViewContext} from "../../component/connected/Connector"
import {defaultState} from "../../default-state"

export const renderComponentWithState = (fragment: React.ReactFragment, state?: AppView) => {
    const {FakeStateProvider, pushedEvents} = makeFakeStateProvider(state)
    const rootElement = renderComponent(
        <FakeStateProvider>
            {fragment}
        </FakeStateProvider>
    )

    return {pushedEvents, rootElement}
}


export const renderComponent = (fragment: React.ReactFragment) => {
    const rootElement = document.createElement("DIV")!
    document.body.innerHTML = ""
    document.body.appendChild(rootElement)
    ReactDOM.render(<React.Fragment>{fragment}</React.Fragment>,  rootElement)

    return rootElement
}


export const makeFakeStateProvider = (state: AppView = defaultState) => {
    // tslint:disable-next-line:readonly-array
    let events: any[] = []

    const FakeStateProvider = (props: PropsWithChildren<{}>) =>
        <AppViewContext.Provider value={{state, pushEvent: (event) => events = [...events, event] }}>
            {props.children}
        </AppViewContext.Provider>

    return {
        FakeStateProvider,
        pushedEvents: () => events
    }
}


export const testHandleSelector = (handle: string): string => `[data-test-handle='${handle}']`
export const queryByTestHandle = (handle: string, element: Element) => element.querySelector(testHandleSelector(handle))!
export const queryAllByTestHandle = (handle: string, element: Element) => element.querySelectorAll(testHandleSelector(handle))
