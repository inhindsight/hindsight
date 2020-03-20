# Define

Present an administration UI for maintaining the platform.
Contains a phoenix backend that maintains the presentation state and a React presentation layer. 
Communication between layers is done via websockets.

## Phoenix Development
Run Tests
`mix test`
Run Server
`mix phx.server`

## React Development
*All commands must be run from assets/*
Run Tests
`npm run test:once`
Run Tests w/ watch
`npm run test`
Compile
`npm run compile`
Lint
`npm run lint`
Lint w/ auto fix
`npm run lint:fix` 
Storybook
`npm run storybook`
Check everything before pushing code (runs compile, test, and lint)
`npm run ci`

