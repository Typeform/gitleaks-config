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

build-public-ecr: build

push-public-ecr:
	docker push $(IMAGE_NAME):${IMAGE_TAG}
