#!/bin/sh

if [ ! -z $DISABLE_SECRET_SCANS ] &&  $DISABLE_SECRET_SCANS == 'true'; then
    echo "Secret scans are disabled. To enable them back, set the environment variable DISABLE_SECRET_SCANS to 'false'"
    exit 0
fi

# This script is supposed to be run from a travis build to check for secrets
# on pull requests.

local_config='.gitleaks.toml'
final_config='gitleaks_config.toml'
gitleaks_config_container="$DOCKER_REGISTRY/typeform/gitleaks-config"
gitleaks_container="$DOCKER_REGISTRY/typeform/gitleaks"

if [ -f ./$local_config ]; then
    # Generate the final gitleaks config file that contains both the global config
    # and the repository config.
    docker container run --rm -v $PWD/$local_config:/app/$local_config \
        $gitleaks_config_container python gitleaks_config_generator.py > $final_config
else
    docker container run --rm $gitleaks_config_container \
        python gitleaks_config_generator.py > $final_config
fi

# Download the gitleaks container. Login to the docker registry must be done
# in the before_install step of Travis
docker pull $gitleaks_container:latest

# Look for secrets in the PR
docker container run --rm --name=gitleaks -v $PWD/$final_config:/tmp/$final_config \
    $gitleaks_container --host=Github --pr=https://github.com/$TRAVIS_REPO_SLUG/pull/$TRAVIS_PULL_REQUEST \
                        --access-token=$GITLEAKS_GITHUB_ACCESS_TOKEN \
                        --config=/tmp/$final_config --verbose --redact

# Autoremove this script when it finishes and maintain the exit code of the
# gitleaks run
exit_code=$?
trap "rm -f $0; exit $exit_code;" EXIT
