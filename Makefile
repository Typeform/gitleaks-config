IMAGE_NAME := ${CONTAINER_REGISTRY}/gitleaks-config
PUBLIC_ECR_IMAGE_NAME := public.ecr.aws/typeform/gitleaks-config
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
		$(IMAGE_NAME):${RELEASE_TAG} \
		python gitleaks_config_generator_tests.py

test-gitleaks-config:
	./test_global_config.sh

test: test-config-generator test-gitleaks-config

push: build
	docker push $(IMAGE_NAME):${RELEASE_TAG}

push-latest: build
	docker push $(IMAGE_NAME):latest

# Temporary until SP-1665 is done
push-quay: IMAGE_NAME=quay.io/typeform/gitleaks-config
push-quay: build
	docker login -u=${DOCKER_USERNAME} -p=${DOCKER_PASSWORD} ${CONTAINER_REGISTRY} quay.io
	docker push $(IMAGE_NAME):${RELEASE_TAG}

push-latest-quay: IMAGE_NAME=quay.io/typeform/gitleaks-config
push-latest-quay: build
	docker login -u=${DOCKER_USERNAME} -p=${DOCKER_PASSWORD} ${CONTAINER_REGISTRY} quay.io
	docker push $(IMAGE_NAME):latest

build-public-ecr: IMAGE_NAME=$(PUBLIC_ECR_IMAGE_NAME)
build-public-ecr: build

push-public-ecr: IMAGE_NAME=$(PUBLIC_ECR_IMAGE_NAME)
push-public-ecr:
	docker push $(IMAGE_NAME):${IMAGE_TAG}
