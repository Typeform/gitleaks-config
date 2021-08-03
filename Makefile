IMAGE_NAME := "quay.io/typeform/gitleaks-config"
RELEASE_TAG ?= dev

all: build run

build:
	docker build -t $(IMAGE_NAME):${RELEASE_TAG} -t $(IMAGE_NAME):latest .

run:
	docker container run --rm -v ${PWD}/.gitleaks.toml:/app/.gitleaks.toml \
		$(IMAGE_NAME):${RELEASE_TAG}

test-config-generator: build
	docker container run --rm -v ${PWD}/test/local-config.toml:/app/local-config.toml \
		-v ${PWD}/test/local-config-old.toml:/app/local-config-old.toml \
		$(IMAGE_NAME):${RELEASE_TAG} \
		python gitleaks_config_generator_tests.py

test-gitleaks-config:
	./test_global_config.sh

test: test-config-generator test-gitleaks-config

push:
	docker push $(IMAGE_NAME):${RELEASE_TAG}

push-latest:
	docker push $(IMAGE_NAME):latest
