FROM node:12.5.0 as npm_builder
COPY apps/service_define/assets/ /app
WORKDIR /app/
RUN npm install \
  && npm run release

FROM bitwalker/alpine-elixir-phoenix:1.9.4 as build
COPY . /opt/app
WORKDIR /opt/app/
COPY --from=npm_builder /app/dist/ apps/service_define/priv/static
RUN mix do \
  local.hex --force, \
  local.rebar --force, \
  deps.get --only prod, \
  deps.compile
ENV MIX_ENV=prod
RUN mix release orchestrate \
  && mix release receive \
  && mix release gather \
  && mix release broadcast \
  && mix release persist \
  && mix release define \
  && mix release acquire

FROM bitwalker/alpine-erlang:22.2.3
ENV PORT=80
EXPOSE ${PORT}
WORKDIR /opt/app
COPY --from=build /opt/app/_build/prod/rel/ .
