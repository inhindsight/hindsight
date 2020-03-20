export interface EventFactory<T> {
    (parameters: T): Event & T

    readonly type: string
}

export interface Event {
    readonly type: string
}

export const createEventFactory = <T>(type: string): EventFactory<T> => {
    const factory = (parameters: T) => ({type, ...parameters})
    factory.type = type
    return factory
}
