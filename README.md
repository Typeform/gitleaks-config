# Gitleaks Config

This repository contains three things:

1. `global_config.toml`: The global configuration we use as a base to run https://github.com/zricethezav/gitleaks
2. `gitleaks_config_generator`: A python script to merge our global configuration with a project's specific configuration
3. `travis_check_secrets.sh`: An sh script to check if there are secrets on a pull request

# How to work with the script

There are different make tasks:

* `make`: builds the docker image and runs the docker container
* `make build`: builds the docker image
* `make run`: runs the docker container
* `make test`: runs tests in the docker container

# How to upload a new image to Quay.io

1. Build the image locally and give it a representative tag name: `docker build -t gitleaks-config:march-20 .`
2. Identify the Image ID of the newly created image: `docker images`
3. Tag the newly created image: `docker tag <IMAGE_ID> quay.io/typeform/gitleaks-config:<version>`
4. Push it to the image repository: `docker push quay.io/typeform/gitleaks-config`