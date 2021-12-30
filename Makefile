IMAGE_NAME := ${ECR_REGISTRY}/gitleaks-config
RELEASE_TAG ?= dev

all: build run

build:
	docker build \
		-t $(IMAGE_NAME):${RELEASE_TAG} \
		-t $(IMAGE_NAME):latest \
		.

run:
	docker container run --rm -v ${PWD}/.gitleaks.toml:/app/.gitleaks.toml \
		$(IMAGE_NAME):${RELEASE_TAG}

test-config-generator:
	docker container run --rm -v ${PWD}/test/local-config.toml:/app/local-config.toml \
		-v ${PWD}/test/local-config-old.toml:/app/local-config-old.toml \
		quay.io/typeform/gitleaks-config:latest \
		python gitleaks_config_generator_tests.py

test-gitleaks-config:
	./test_global_config.sh

test: test-config-generator test-gitleaks-config

push:
	docker push $(IMAGE_NAME):${RELEASE_TAG}

custom-push-ecr:
	docker push $(IMAGE_NAME):1.8.0

push-latest:
	docker push $(IMAGE_NAME):latest
