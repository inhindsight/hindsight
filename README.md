# Hindsight

Data is clearer in Hindsight

## Usage

## Installation

Hindsight requires you to use [Helm](https://helm.sh) v3. Our [.tool-versions](./.tool-versions) file will enforce the correct software dependencies for you if you're using [asdf](https://asdf-vm.com).

Hindsight currently uses [Kafka](https://kafka.apache.org/) to decouple services, and we suggest using [Strimzi](https://github.com/strimzi/strimzi-kafka-operator) to deploy Kafka to Kubernetes. The helm chart assumes you'll use Strimzi but does not install it. You must do that yourself or toggle Strimzi off via helm values (`--set strimzi.enabled=false`).

Our [install](./scripts/install) script will install Strimzi, wait for a `Ready` state, then deploy Hindsight.

```bash
./scripts/install [RELEASE_NAME] [NAMESPACE] [values]
```

### Versioning

By default, `.Chart.AppVersion` from our Helm chart will be deployed. This can be overwritten by setting `image.tag`. The `latest` tag is auto-published to Docker [hub](https://hub.docker.com/r/inhindsight/hindsight) on every merge to master, so use it to get the latest-and-greatest updates. Make sure you set `image.pullPolicy` to `Always` when you do it:

```bash
./scripts/install [RELEASE_NAME] [NAMESPACE] image.tag=latest image.pullPolicy=Always [...]
```

### AWS

To deploy to AWS, we suggest you start with:

```bash
./scripts/install [RELEASE_NAME] [NAMESPACE] \
                  global.objectStore.bucketName=[BUCKET_NAME] \
                  global.objectStore.region=[AWS_REGION] \
                  presto.minio.enable=false \
                  presto.postgres.enable=false \
                  presto.postgres.service.externalAddress=[RDS_URL] \
                  presto.postgres.db.password=[DB_PASSWORD]
```
