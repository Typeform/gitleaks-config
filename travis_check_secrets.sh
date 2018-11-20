#!/bin/sh

# This script is supposed to be run from a travis build to check for secrets
# on pull requests.

secretsignore='.secretsignore'
final_config='gitleaks_config.toml'
gitleaks_container="$DOCKER_REGISTRY/typeform/gitleaks"

# Move to the gitleaks-config directory
cd "$(dirname "$0")"

if [ -f ../$secretsignore ]; then
    # Copy the project specific .secretsignore file
    cp ../$secretsignore .

    # Generate the final gitleaks config file that contains both the global config
    # and the repository config.
    make build
    docker container run --rm -v $PWD/$secretsignore:/app/$secretsignore gitleaks-config > $final_config
else
    # When the .secretsignore file doesn't exists, we only have to use the
    # global config.
    cp global_config.toml $final_config
fi

# Download the gitleaks container. Login to the docker registry must be done
# in the before_install step of Travis
docker pull $gitleaks_container:latest

# Look for secrets in the PR
docker container run --rm --name=gitleaks -e GITHUB_TOKEN=$GITLEAKS_GITHUB_ACCESS_TOKEN \
    -v $PWD/$final_config:/tmp/$final_config \
    $gitleaks_container --github-pr=https://github.com/$TRAVIS_REPO_SLUG/pull/$TRAVIS_PULL_REQUEST \
                        --config=/tmp/$final_config --verbose

