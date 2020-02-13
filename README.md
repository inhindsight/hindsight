# Hindsight

Data is clearer in Hindsight

## Usage

## Installation

Hindsight requires you to use [Helm](https://helm.sh) v3. Our [.tool-versions](./.tool-versions) file will enforce the correct software dependencies for you if you're using [asdf](https://asdf-vm.com).

Hindsight currently uses [Kafka](https://kafka.apache.org/) to decouple services, and we suggest using [Strimzi](https://github.com/strimzi/strimzi-kafka-operator) to deploy Kafka to Kubernetes. The helm chart assumes you'll use Strimzi but does not install it. You must do that yourself or toggle Strimzi off via helm values (`--set strimzi.enabled=false`).

```bash
helm repo add strimzi https://strimzi.io/charts/
helm install strimzi-kafka-operator strimzi/strimzi-kafka-operator --version 0.16.2 [opts]
```

Once Strimzi's CRDs are defined, install Hindsight with:

```bash
helm install [NAME] ./helm [opts]
```
