# Gitleaks Config

This repository contains three things:

1. `global_config.toml`: The global configuration we use as a base to run https://github.com/zricethezav/gitleaks
2. `gitleaks_config_generator`: A python script to merge our global configuration with a project's specific configuration
3. `travis_check_secrets.sh`: An sh script to check if there are secrets on a pull request

# How to work with the script

There are different make tasks:

`make`: builds the docker image and runs the docker container
`make build`: builds the docker image
`make run`: runs the docker container
`make test`: runs tests in the docker container

