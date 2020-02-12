# Hindsight

Data is clearer in Hindsight

## Usage

### Installation

Hindsight uses Kafka to decouple services, and we suggest using [strimzi](https://github.com/strimzi/strimzi-kafka-operator) to deploy Kafka to Kubernetes.
Hindsight's helm chart assumes Strimzi by default, but does not install it. You must do that yourself or toggle Kafka off via helm values (`--set strimzi.enabled=false`).

```bash
helm repo add strimzi https://strimzi.io/charts/
helm install strimzi-kafka-operator strimzi/strimzi-kafka-operator --version 0.16.2 [opts]
```

Once strimzi's CRDs are defined, you can install Hindsight with:

```bash
helm install [NAME] ./helm [opts]
```
