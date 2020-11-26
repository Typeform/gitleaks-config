IMAGE_NAME := "quay.io/typeform/gitleaks-config"

all: build run

build:
	docker image build -t $(IMAGE_NAME) .

run:
	docker container run --rm -v ${PWD}/.gitleaks.toml:/app/.gitleaks.toml $(IMAGE_NAME)

test-config-generator: build
	docker container run --rm -v ${PWD}/.gitleaks.toml:/app/.gitleaks.toml \
		-v ${PWD}/.gitleaks-old.toml:/app/.gitleaks-old.toml $(IMAGE_NAME) \
		   python gitleaks_config_generator_tests.py

test-gitleaks-config:
	./test_global_config.sh

test: test-config-generator test-gitleaks-config