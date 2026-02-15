# Dapr Agents - Configuration Reference

For the full configuration, refer to [values.yaml](https://github.com/CasperGN/dapr-agents-dev/blob/main/dapr-agents/values.yaml).

## Core Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `registry` | Docker registry used for images | `localhost:5001` |
| `global.logLevel` | Global log level for components | `DEBUG` |

## Monitoring Stack

| Parameter | Description | Default |
|-----------|-------------|---------|
| `monitoring.enabled` | Enable the monitoring stack | `true` |
| `loki.enabled` | Enable Loki for log aggregation | `true` |
| `tempo.enabled` | Enable Tempo for distributed tracing | `true` |
| `kube-prometheus-stack.enabled` | Enable Prometheus + Grafana | `true` |
| `kube-prometheus-stack.grafana.adminUser` | Grafana admin username | `admin` |
| `kube-prometheus-stack.grafana.adminPassword` | Grafana admin password | `admin` |
| `opentelemetry-collector.enabled` | Enable OpenTelemetry Collector | `true` |

## Kagent

| Parameter | Description | Default |
|-----------|-------------|---------|
| `kagent.enabled` | Enable Kagent controller and UI | `true` |
| `kagent.kmcp.enabled` | Enable KMCP (MCP server for Kagent) | `true` |
| `kagent.providers.default` | Default LLM provider for Kagent | `ollama` |
| `kagent.providers.openAI.apiKey` | OpenAI API key for Kagent | `""` |
| `kagent.providers.ollama.model` | Ollama model for Kagent | `llama3.2:latest` |

## Dapr

| Parameter | Description | Default |
|-----------|-------------|---------|
| `dapr.enabled` | Enable Dapr control plane | `true` |

## Redis

| Parameter | Description | Default |
|-----------|-------------|---------|
| `redis.enabled` | Enable Redis (state store / pubsub) | `true` |
| `redis.image` | Redis container image | `redis` |
| `redis.tag` | Redis image tag | `6.2` |
| `redis.password` | Redis password (empty = no auth) | `""` |
| `redisConfig.serviceName` | Redis service name | `dapr-redis-master` |
| `redisInsight.enabled` | Enable RedisInsight UI | `true` |

## LLM Provider

| Parameter | Description | Default |
|-----------|-------------|---------|
| `llm.provider` | Default LLM provider (`ollama` or `openAI`) | `ollama` |
| `llm.apiKey` | API key for the LLM provider | `dummy-key` |
| `llm.ollama.enabled` | Enable Ollama provider | `true` |
| `llm.ollama.model` | Ollama model name | `llama3.2:latest` |
| `llm.ollama.endpoint` | Ollama API endpoint | `http://host.docker.internal:11434/v1` |
| `llm.openAI.model` | OpenAI model name | `gpt-4o-mini` |

## OpenTelemetry

| Parameter | Description | Default |
|-----------|-------------|---------|
| `opentelemetry.enabled` | Enable OTEL config (tracing, Redis seed) | `true` |
| `opentelemetry.endpoint` | OTEL collector gRPC endpoint | `dapr-agents-opentelemetry-collector.dapr-agents.svc.cluster.local:4317` |
| `opentelemetry.protocol` | OTEL export protocol | `grpc` |

## Application Secrets

| Parameter | Description | Default |
|-----------|-------------|---------|
| `appSecrets` | Array of secrets to create in `app-secrets` Secret | `[]` |

Each entry in `appSecrets` has `name` and `value`:
```yaml
appSecrets:
  - name: my-api-key
    value: secret123
  - name: db-password
    value: pass456
```

## Other

| Parameter | Description | Default |
|-----------|-------------|---------|
| `diagridDashboard.enabled` | Enable Diagrid Dapr Dashboard | `true` |
| `gateway.enabled` | Enable the stack gateway | `true` |
| `externalWebhook.url` | External webhook URL | `http://localhost:8000` |
| `agents` | Custom Dapr agent definitions | `{}` |
