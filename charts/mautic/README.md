# Mautic Helm Charts

Mautic is an open source marketing automation platform that provides you with the greatest level of audience intelligence, thus enabling you to make more meaningful customer connections. Use Mautic to engage your customers and create an efficient marketing strategy.

[Overview of Mautic](https://docs.mautic.org/en/overview-of-mautic)



## TL;DR

```console
helm repo add my-repo https://nurfaizin.github.io/helm-charts
helm install my-release my-repo/mautic
```

## Introduction

This chart bootstraps a [Mautic](https://github.com/mautic/mautic) deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

It also packages the [Bitnami MariaDB chart](https://github.com/bitnami/charts/tree/main/bitnami/mariadb) which is required for bootstrapping a MariaDB deployment for the database requirements of the Mautic application, and the [Bitnami Redis chart](https://github.com/bitnami/charts/tree/main/bitnami/redis) which is required for bootstrapping a MariaDB deployment for the queue requirements.

Bitnami charts can be used with [Kubeapps](https://kubeapps.dev/) for deployment and management of Helm Charts in clusters.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure
- StorageClass that support ReadWriteMany access mode

## Installing the Chart

To install the chart with the release name `my-release`:

```console
helm repo add my-repo https://nurfaizin.github.io/helm-charts
helm install my-release my-repo/mautic
```

The command deploys WordPress on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.
