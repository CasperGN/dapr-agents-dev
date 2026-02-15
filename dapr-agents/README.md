# Dapr Agents Helm Chart

A comprehensive developer stack for working with Dapr, Monitoring (Loki, Tempo, Prometheus, Grafana), OpenTelemetry, and Kagent. This chart consolidates everything into a single namespace for easy development and testing.

## Introduction

This Helm chart simplifies the deployment of a complete Dapr-based agentic ecosystem. It includes the Dapr control plane, a full observability stack, Redis for state and pubsub, and the Kagent controller for managing AI agents.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.10+
- Ollama or OpenAI API Key

## Installation

### Add Helm Repository

```bash
helm repo add dapr-agents https://caspergn.github.io/dapr-agents-dev/
helm repo update
```

### Install Chart

```bash
helm install dapr-agents dapr-agents/dapr-agents --namespace dapr-agents --create-namespace
```

## Configuration

The following table lists the configurable parameters of the Dapr Agents chart and their default values.

### Core Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `registry` | Docker registry used for images | `localhost:5001` |
| `global.logLevel` | Global log level for components | `DEBUG` |

### Monitoring Stack

| Parameter | Description | Default |
|-----------|-------------|---------|
| `monitoring.enabled` | Enable the monitoring stack | `true` |
| `loki.enabled` | Enable Loki for log aggregation | `true` |
| `tempo.enabled` | Enable Tempo for distributed tracing | `true` |
| `kube-prometheus-stack.enabled` | Enable Prometheus + Grafana | `true` |
| `opentelemetry-collector.enabled` | Enable OpenTelemetry Collector | `true` |

### Kagent

| Parameter | Description | Default |
|-----------|-------------|---------|
| `kagent.enabled` | Enable Kagent controller and UI | `true` |
| `kagent.providers.default` | Default LLM provider for Kagent | `ollama` |

### Dapr

| Parameter | Description | Default |
|-----------|-------------|---------|
| `dapr.enabled` | Enable Dapr control plane | `true` |

### Redis

| Parameter | Description | Default |
|-----------|-------------|---------|
| `redis.enabled` | Enable Redis (state store / pubsub) | `true` |

For a complete list of parameters, see the [values.yaml](values.yaml).

## Accessing Dashboards

If using the default configuration with the gateway enabled, you can access the dashboards via:

- **Kagent UI**: `http://kagent.localhost:8080`
- **Grafana**: `http://grafana.localhost:8080`
- **Redis Insight**: `http://redis.localhost:8080`
- **Diagrid Dashboard**: `http://diagrid.localhost:8080`

## Maintainers

| Name | Email |
|------|-------|
| CasperGN | casper@diagrid.io |
