import React from "react"

interface MessageProps {
    readonly message: string,
    readonly clicked: (number: number) => void
}

export const Message = ({message, clicked}: MessageProps) =>
    <h1 onClick={() => clicked(Math.random()) } data-test-handle={MessageTestHandles.Message}>
        {message}
    </h1>

export enum MessageTestHandles {
    Message = "MESSAGE_MESSAGE"
}
