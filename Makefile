IMAGE_NAME := public.ecr.aws/typeform/gitleaks-config
IMAGE_TAG ?= dev

all: build run

build:
	docker build \
		-t $(IMAGE_NAME):${IMAGE_TAG} \
		-t $(IMAGE_NAME):latest \
		.

run:
	docker container run --rm -v ${PWD}/.gitleaks.toml:/app/.gitleaks.toml \
		$(IMAGE_NAME):${IMAGE_TAG}

test-config-generator:
	docker container run --rm -v ${PWD}/test/local-config.toml:/app/local-config.toml \
		$(IMAGE_NAME):${IMAGE_TAG} \
		python gitleaks_config_generator_tests.py

test-gitleaks-config:
	./test_global_config.sh

test: test-config-generator test-gitleaks-config

build-amd64:
	docker buildx build \
		--platform linux/amd64 \
		-t $(IMAGE_NAME):${IMAGE_TAG}-amd64 \
		--load \
		.

build-arm64:
	docker buildx build \
		--platform linux/arm64 \
		-t $(IMAGE_NAME):${IMAGE_TAG}-arm64 \
		--load \
		.

build-multiarch-local: build-amd64 build-arm64

push-multiarch:
	docker buildx build \
		--platform linux/amd64,linux/arm64 \
		-t $(IMAGE_NAME):${IMAGE_TAG} \
		-t $(IMAGE_NAME):latest \
		--push \
		.

# Public ECR Jenkins file required targets
build-public-ecr: build-multiarch-local

push-public-ecr: push-multiarch
