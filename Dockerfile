FROM bitwalker/alpine-elixir-phoenix:1.9.4 as build
COPY . /opt/app
WORKDIR /opt/app/
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
RUN rm -r _build/prod/rel/define/lib/service_define-0.1.0/priv/static/ \
  && cd apps/service_define/assets \
  && npm install \
  && npm run release \
  && cd - \
  && cp -r apps/service_define/assets/dist _build/prod/rel/define/lib/service_define-0.1.0/priv/static

FROM bitwalker/alpine-erlang:22.2.3
ENV PORT=80
EXPOSE ${PORT}
WORKDIR /opt/app
COPY --from=build /opt/app/_build/prod/rel/ .
