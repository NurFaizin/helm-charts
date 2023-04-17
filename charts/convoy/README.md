# Convoy Helm Charts

Convoy is an open-source high-performance webhooks gateway to manage millions of webhooks end-to-end. It is designed to be an highly scalable multi-tenant webhooks gateway to support multiple backend services sending and receiving webhooks. It comes baked in with several features like retries, rate limiting, circuit breaking, customer-facing webhooks dashboards, support for both sending & receiving webhooks and a lot more.

[Overview of Convoy](https://getconvoy.io/docs/introduction)



## TL;DR

```console
helm repo add my-repo https://nurfaizin.github.io/helm-charts
helm install my-release my-repo/convoy
```

## Introduction

This chart bootstraps a [Convoy](https://github.com/frain-dev/convoy) deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

It also packages the [Bitnami PostgreSQL chart](https://github.com/bitnami/charts/tree/main/bitnami/postgresql) which is required for bootstrapping a PostgreSQL deployment for the database requirements of the Convoy application, and the [Bitnami Redis chart](https://github.com/bitnami/charts/tree/main/bitnami/redis) which is required for bootstrapping a PostgreSQL deployment for the queue requirements.

Bitnami charts can be used with [Kubeapps](https://kubeapps.dev/) for deployment and management of Helm Charts in clusters.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure

## Installing the Chart

To install the chart with the release name `my-release`:

```console
helm repo add my-repo https://nurfaizin.github.io/helm-charts
helm install my-release my-repo/convoy
```

The command deploys WordPress on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.
