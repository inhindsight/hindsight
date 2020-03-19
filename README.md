# Hindsight

Data is clearer in Hindsight

## Usage

## Running Hindsight

### Locally

The `platform_runner` app serves as our way to stand up an instance on `localhost`. It is also how we run end-to-end tests. To run/debug/play locally:

```bash
cd apps/platform_runner
MIX_ENV=integration mix docker.start
MIX_ENV=integration iex -S mix
```

Our WebSocket and REST APIs can be reached locally on ports `4000` and `4001`, respectively.

### In Kubernetes

Hindsight requires you to use [Helm](https://helm.sh) v3. Our [.tool-versions](./.tool-versions) file will enforce the correct software dependencies for you if you're using [asdf](https://asdf-vm.com).

Hindsight currently uses [Kafka](https://kafka.apache.org/) to decouple services, and we suggest using [Strimzi](https://github.com/strimzi/strimzi-kafka-operator) to deploy Kafka to Kubernetes. The helm chart assumes you'll use Strimzi but does not install it. You must do that yourself or toggle Strimzi off via helm values (`--set strimzi.enabled=false`).

Our [install](./scripts/install) script will install Strimzi, wait for a `Ready` state, then deploy Hindsight.

```bash
./scripts/install [RELEASE_NAME] [NAMESPACE] [aws|local] [values]
```

#### Versioning

By default, `.Chart.AppVersion` from our Helm chart will be deployed. This can be overwritten by setting `image.tag`. The `latest` tag is auto-published to Docker [hub](https://hub.docker.com/r/inhindsight/hindsight) on every merge to master, so use it to get the latest-and-greatest updates. Make sure you set `image.pullPolicy` to `Always` when you do it:

```bash
./scripts/install [RELEASE_NAME] [NAMESPACE] aws image.tag=latest ingress.host=mydomain.com
./scripts/install [RELEASE_NAME] [NAMESPACE] local image.tag=latest
```

#### Minikube

Set location to `local` to deploy to Minikube or Docker's Kubernetes.

```bash
./scripts/install [RELEASE_NAME] [NAMESPACE] local image.tag=latest image.pullPolicy=Always
```

#### AWS

Set location to `aws` to use AWS presets. You must give external service information.

```bash
./scripts/install [RELEASE_NAME] [NAMESPACE] aws \
                  global.objectStore.bucketName=[BUCKET_NAME] \
                  global.objectStore.region=[AWS_REGION] \
                  presto.postgres.externalAddress=[RDS_URL] \
                  presto.postgres.db.password=[DB_PASSWORD] \
                  presto.postgres.db.user=[DB_USER] \
                  redis.externalAddress=[REDIS_URL]
```
