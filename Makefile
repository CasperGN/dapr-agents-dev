# --- Configuration ---
CLUSTER_NAME ?= dapr-agents
REG_PORT     ?= 5001
REG_NAME     ?= kind-registry
REG_IMAGE    ?= registry:2
KIND_CONFIG  ?= kind-config.yaml

TEST_CLUSTER_NAME ?= dapr-agents-test
TEST_KIND_CONFIG  ?= tests/kind-config-test.yaml
MIRROR_CACHE      ?= /tmp/registry-mirror-cache

# List of registries to mirror: <host>,<remote_url>
# Using comma as separator to avoid shell pipe issues.
MIRRORS = docker.io,https://registry-1.docker.io \
          ghcr.io,https://ghcr.io \
          quay.io,https://quay.io \
          gcr.io,https://gcr.io \
          registry.k8s.io,https://registry.k8s.io

.PHONY: help
help:
	@echo "Usage: make [target]"
	@echo "Targets:"
	@echo "  cluster-up    Create kind cluster with local registry and mirrors"
	@echo "  cluster-down  Delete cluster and stop registry/mirrors"
	@echo "  install       Deploy the stack using Helm"
	@echo "  status        Check pod status"
	@echo "  test-lint     Run helm lint"
	@echo "  test-template Render and validate templates with kubeconform"
	@echo "  test-chainsaw Run Chainsaw integration tests"
	@echo "  test          Run all tests (lint + template + chainsaw)"
	@echo "  all           Create cluster and install the full stack"

# ---------------------------------------------------------------------------
# Mirror helpers (shared by cluster-up and test-chainsaw)
# ---------------------------------------------------------------------------
define start-mirrors
	@for mirror in $(MIRRORS); do \
		host=`echo $$mirror | cut -d',' -f1`; \
		url=`echo $$mirror | cut -d',' -f2`; \
		name=`echo $$host | sed 's/\./-/g'`; \
		reg_mirror_name="kind-mirror-$$name"; \
		cache_dir="$(1)/$$name"; \
		mkdir -p "$$cache_dir"; \
		if [ "`docker inspect -f '{{.State.Running}}' $$reg_mirror_name 2>/dev/null || true`" != "true" ]; then \
			echo "-> Starting mirror for $$host"; \
			docker rm -f "$$reg_mirror_name" 2>/dev/null || true; \
			docker run -d --restart=always --network bridge \
				--name "$$reg_mirror_name" \
				-v "$$cache_dir:/var/lib/registry" \
				-e REGISTRY_PROXY_REMOTEURL=$$url $(REG_IMAGE); \
		fi; \
	done
endef

define configure-mirrors
	@for node in `kind get nodes --name $(1)`; do \
		for mirror in $(MIRRORS); do \
			host=`echo $$mirror | cut -d',' -f1`; \
			name=`echo $$host | sed 's/\./-/g'`; \
			reg_mirror_name="kind-mirror-$$name"; \
			dir="/etc/containerd/certs.d/$$host"; \
			docker exec "$$node" mkdir -p "$$dir"; \
			echo '[host."http://'$$reg_mirror_name':5000"]' \
				| docker exec -i "$$node" cp /dev/stdin "$$dir/hosts.toml"; \
		done; \
	done
endef

define connect-mirrors
	@for mirror in $(MIRRORS); do \
		host=`echo $$mirror | cut -d',' -f1`; \
		name=`echo $$host | sed 's/\./-/g'`; \
		reg_mirror_name="kind-mirror-$$name"; \
		if [ "`docker inspect -f='{{json .NetworkSettings.Networks.kind}}' $$reg_mirror_name 2>/dev/null`" = "null" ]; then \
			docker network connect "kind" "$$reg_mirror_name"; \
		fi; \
	done
endef

# ---------------------------------------------------------------------------
# Cluster lifecycle
# ---------------------------------------------------------------------------
.PHONY: cluster-up
cluster-up:
	@echo "### Starting local dev registry and mirrors... ###"
	@if [ "`docker inspect -f '{{.State.Running}}' $(REG_NAME) 2>/dev/null || true`" != "true" ]; then \
		docker run -d --restart=always -p "127.0.0.1:$(REG_PORT):5000" --network bridge --name "$(REG_NAME)" $(REG_IMAGE); \
	else \
		docker start $(REG_NAME) 2>/dev/null || true; \
	fi
	$(call start-mirrors,/tmp/dev-mirror-cache)
	@echo "### Creating kind cluster... ###"
	@kind create cluster --name $(CLUSTER_NAME) --config $(KIND_CONFIG)
	@echo "### Configuring registry access on nodes... ###"
	@for node in `kind get nodes --name $(CLUSTER_NAME)`; do \
		dir="/etc/containerd/certs.d/localhost:$(REG_PORT)"; \
		docker exec "$$node" mkdir -p "$$dir"; \
		echo '[host."http://$(REG_NAME):5000"]' | docker exec -i "$$node" cp /dev/stdin "$$dir/hosts.toml"; \
	done
	$(call configure-mirrors,$(CLUSTER_NAME))
	@echo "### Connecting registries to cluster network... ###"
	@if [ "`docker inspect -f='{{json .NetworkSettings.Networks.kind}}' $(REG_NAME)`" = "null" ]; then \
		docker network connect "kind" "$(REG_NAME)"; \
	fi
	$(call connect-mirrors)
	@echo "### Documenting local registry... ###"
	@printf "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: local-registry-hosting\n  namespace: kube-public\ndata:\n  localRegistryHosting.v1: |\n    host: \"localhost:$(REG_PORT)\"\n    help: \"https://kind.sigs.k8s.io/docs/user/local-registry/\"\n" | kubectl apply -f -

.PHONY: cluster-down
cluster-down:
	@echo "### Tearing down environment... ###"
	@kind delete cluster --name $(CLUSTER_NAME)

.PHONY: install
install:
	@echo "### Installing stack... ###"
	@helm dependency update ./dapr-agents
	@helm upgrade --install dapr-agents ./dapr-agents \
		--namespace dapr-agents --create-namespace \
		--set llm.apiKey=$(OPENAI_API_KEY)

.PHONY: status
status:
	@kubectl get pods -n dapr-agents

# ---------------------------------------------------------------------------
# Testing
# ---------------------------------------------------------------------------
.PHONY: test-lint
test-lint:
	@echo "### Running helm lint... ###"
	@helm lint ./dapr-agents --set llm.apiKey=lint-key --set monitoring.enabled=false --set kagent.enabled=false
	@helm lint ./dapr-agents --set llm.apiKey=lint-key

.PHONY: test-template
test-template:
	@echo "### Rendering and validating templates... ###"
	@helm template dapr-agents ./dapr-agents \
		--namespace dapr-agents \
		--set monitoring.enabled=false \
		--set kagent.enabled=false \
		--set dapr.enabled=false \
		--set llm.apiKey=test-key \
		| kubeconform -strict -summary -schema-location default -skip CustomResourceDefinition,Component,HTTPEndpoint,Agent,Memory,ModelConfig,RemoteMCPServer,ToolServer,MCPServer

.PHONY: test-chainsaw
test-chainsaw:
	@echo "### Running Chainsaw integration tests... ###"
	@helm dependency update ./dapr-agents
	@echo "### Starting registry mirrors... ###"
	$(call start-mirrors,$(MIRROR_CACHE))
	@echo "### Creating Kind cluster... ###"
	@kind create cluster --name $(TEST_CLUSTER_NAME) --config $(TEST_KIND_CONFIG) || true
	$(call configure-mirrors,$(TEST_CLUSTER_NAME))
	$(call connect-mirrors)
	@echo "### Installing chart... ###"
	@helm upgrade --install dapr-agents ./dapr-agents \
		--namespace dapr-agents --create-namespace \
		--set llm.apiKey=ci-test-key \
		--kube-context kind-$(TEST_CLUSTER_NAME) \
		--timeout 10m
	@chainsaw test tests/chainsaw/ \
		--parallel 1 \
		--report-format JSON \
		--report-name chainsaw-results \
		--kube-context kind-$(TEST_CLUSTER_NAME); \
		exit_code=$$?; \
		kind delete cluster --name $(TEST_CLUSTER_NAME); \
		exit $$exit_code

.PHONY: test
test: test-lint test-template test-chainsaw

.PHONY: all
all: cluster-up install
