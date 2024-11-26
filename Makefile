SHELL=/bin/bash -o pipefail

REGISTRY   ?= ghcr.io/appscode-images
BIN        ?= ingress-nginx-controller
IMAGE      := $(REGISTRY)/$(BIN)
TAG        ?= $(shell git describe --exact-match --abbrev=0 2>/dev/null || echo "")

BASEIMAGE  ?= registry.k8s.io/ingress-nginx/controller:$(TAG)
# PLATFORM   ?= linux/$(subst x86_64,amd64,$(subst aarch64,arm64,$(shell uname -m)))
PLATFORM   ?= linux/amd64,linux/arm64

BUILD_DIRS := bin

.PHONY: release
release: $(BUILD_DIRS)
	sed \
		-e 's|{ARG_FROM}|$(BASEIMAGE)|g' \
		Dockerfile > bin/Dockerfile
	docker buildx create --name container --driver=docker-container || true
	docker build --push \
		--builder container --platform $(PLATFORM) \
		-t $(IMAGE):$(TAG) -f bin/Dockerfile .

$(BUILD_DIRS):
	@mkdir -p $@

.PHONY: fmt
fmt:
	@find . -path ./vendor -prune -o -name '*.sh' -exec shfmt -l -w -ci -i 4 {} \;

.PHONY: verify
verify: fmt
	@if !(git diff --exit-code HEAD); then \
		echo "files are out of date, run make fmt"; exit 1; \
	fi

.PHONY: ci
ci: verify

# make and load docker image to kind cluster
.PHONY: push-to-kind
push-to-kind: container
	@echo "Loading docker image into kind cluster...."
	@kind load docker-image $(IMAGE):$(TAG)
	@echo "Image has been pushed successfully into kind cluster."
