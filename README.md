# Dapr Agents Stack

A comprehensive developer setup for working with Dapr, Monitoring (Loki, Tempo, Prometheus), and Kagent. This stack consolidates everything into a single namespace for easy local development and testing.

## Prerequisites

- [kind](https://kind.sigs.k8s.io/)
- [helm](https://helm.sh/)
- [docker](https://www.docker.com/)

## Setup

### 1. Create the Cluster
Use the provided `Makefile` to spin up a local kind cluster with a local registry and necessary mirrors:
```bash
make cluster-up
```

### 2. Install the Stack
Deploy the entire stack into the `dapr-agents` namespace. You'll need to provide an OpenAI API key for Kagent:
```bash
# Deploy everything
helm upgrade --install dapr-agents ./dapr-agents \
  --namespace dapr-agents \
  --create-namespace \
  --set kagent.providers.openAI.apiKey=$OPENAI_API_KEY
```

## Accessing Tools

The stack uses a gateway to expose various dashboards and APIs via subdomains on port `8080`. Modern browsers on macOS typically resolve `.localhost` subdomains to `127.0.0.1` automatically.

- **Gateway Landing Page**: [http://localhost:8080](http://localhost:8080)
- **Kagent UI**: [http://kagent.localhost:8080](http://kagent.localhost:8080)
- **Grafana**: [http://grafana.localhost:8080](http://grafana.localhost:8080) (User: `admin`, Password: `admin`)
- **Redis Insight**: [http://redis.localhost:8080](http://redis.localhost:8080)
- **Diagrid Dashboard**: [http://diagrid.localhost:8080](http://diagrid.localhost:8080)

*Note: If these subdomains do not resolve, you may need to add them to your `/etc/hosts` file:*
```text
127.0.0.1 kagent.localhost grafana.localhost redis.localhost diagrid.localhost
```

## Configuration (values.yaml)

The following table lists the configurable parameters of the Dapr Agents chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `registry` | Docker registry used for images | `localhost:5001` |
| `global.logLevel` | Global log level for components | `DEBUG` |
| `monitoring.enabled` | Enable the monitoring stack (Loki, Tempo, Prometheus) | `true` |
| `kube-prometheus-stack.grafana.adminUser` | Admin username for Grafana | `admin` |
| `kube-prometheus-stack.grafana.adminPassword` | Admin password for Grafana | `admin` |
| `kagent.enabled` | Enable Kagent controller and UI | `true` |
| `kagent.kmcp.enabled` | Enable KMCP (MCP server for Kagent) | `true` |
| `dapr.enabled` | Enable Dapr control plane | `true` |
| `redis.enabled` | Enable Redis (used as Dapr state store/pubsub) | `true` |
| `redisInsight.enabled` | Enable RedisInsight UI | `true` |
| `diagridDashboard.enabled` | Enable Diagrid Dapr Dashboard | `true` |
| `gateway.enabled` | Enable the stack gateway | `true` |
| `llm.provider` | Default LLM provider (e.g., ollama, openAI) | `ollama` |
| `llm.ollama.enabled` | Enable Ollama provider | `true` |
| `llm.ollama.model` | Ollama model name | `llama3.2:latest` |
| `llm.ollama.endpoint` | Ollama API endpoint | `http://host.docker.internal:11434` |
| `llm.openAI.model` | OpenAI model name | `gpt-4o-mini` |
| `llm.apiKey` | API key for the LLM provider | `dummy-key` |

For more detailed configuration, refer to the [values.yaml](./dapr-agents/values.yaml) file.

## Development

Use the `Makefile` to manage your environment:

- `make cluster-up`: Create kind cluster with local registry.
- `make cluster-down`: Delete cluster and stop registry.
- `make install`: Deploy the stack using Helm.
- `make status`: Check the status of pods in the `dapr-agents` namespace.
