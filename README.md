# Gitleaks Config

[![Build Status](https://github.com/Typeform/gitleaks-config/actions/workflows/ci.yaml/badge.svg)](https://github.com/Typeform/gitleaks-config/actions/workflows/ci.yaml)
[![Docker Image](https://img.shields.io/badge/quay.io-docker%20image-blue?logo=docker)](https://quay.io/repository/typeform/gitleaks-config)
[![Security](https://img.shields.io/badge/slack-%23security__operations-blue.svg?logo=slack)](https://typeform.slack.com/archives/CCWDN8ASJ)

The main elements of this repository are:

1. `global_config.toml`: The global configuration we use as a base to run https://github.com/zricethezav/gitleaks
2. `gitleaks_config_generator`: A python script to merge our global configuration with a project's specific configuration

# How to work with the script

There are different `make` tasks:

* `make`: builds the docker image and runs the docker container
* `make build`: builds the docker image
* `make run`: runs the docker container
* `make test`: runs tests in the docker container

# Tests

There are two `make` tasks that perform some tests.

`make test-config-generator` validates that a correct `gitleaks` configuration is generated when trying to merge the base one with a custom one. Repos might have custom `gitleaks` configurations to avoid false positives.

`make test-gitleaks-config` runs `gitleaks` with the base configuration against all the files in `test_data/`. This ensures that any change in `global_config.toml` does not produce false positives or false negatives. The script `test_global_config.sh` will run `gitleaks` on every file in `test_data/secrets` and expect to detect secrets. Also, it will run `gitleaks` on every file in `test_data/no_secrets` and expect to not find any secret.

Both test tasks are run in this repo's GitHub Actions workflow.

# How to upload a new image to Quay.io

1. Build the image locally and give it a representative tag name: `docker build -t gitleaks-config:march-20 .`
2. Identify the Image ID of the newly created image: `docker images`
3. Tag the newly created image: `docker tag <IMAGE_ID> quay.io/typeform/gitleaks-config:<version>`
4. Push it to the image repository: `docker push quay.io/typeform/gitleaks-config`
