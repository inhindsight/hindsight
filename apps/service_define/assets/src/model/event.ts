import {createEventFactory} from "../util/event"

export interface NewGreetingEvent {
    readonly greeting: string
}

export const newGreeting = createEventFactory<NewGreetingEvent>("new_greeting")
