IMAGE_NAME := "quay.io/typeform/gitleaks-config"

all: build run

build:
	docker image build -t $(IMAGE_NAME) .

run:
	docker container run --rm -v ${PWD}/.gitleaks.toml:/app/.gitleaks.toml $(IMAGE_NAME)

test: build
	docker container run --rm -v ${PWD}/.gitleaks.toml:/app/.gitleaks.toml $(IMAGE_NAME) \
		   python gitleaks_config_generator_tests.py
