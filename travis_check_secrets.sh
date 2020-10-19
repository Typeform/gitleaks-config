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

# Print gitleaks version
gitleaks_version=$(docker container run --rm --name=gitleaks $gitleaks_container --version)
echo "Starting secrets scan with gitleaks ${gitleaks_version}"

# Look for secrets in the PR
docker container run --rm --name=gitleaks -v $PWD/$final_config:/tmp/$final_config \
    $gitleaks_container --host=Github --pr=https://github.com/$TRAVIS_REPO_SLUG/pull/$TRAVIS_PULL_REQUEST \
                        --access-token=$GITLEAKS_GITHUB_ACCESS_TOKEN \
                        --config=/tmp/$final_config --verbose --redact

# Maintain the exit code of the gitleaks run
exit_code=$?

# If a secret was detected show what to do next
notion_page='https://www.notion.so/typeform/Detecting-Secrets-and-Keeping-Them-Secret-c2c427bf1ded4b908ce9b2746ffcde88'

if [ $exit_code -eq 0 ]; then
    echo "Scan finished. No secrets were detected"
elif [ $exit_code -eq 1 ]; then
    echo "Scan finished. Looks like one or more secrets were uploaded, check out this Notion page to know what to do next ${notion_page}"
else
    echo "Error scanning"
fi

# Autoremove this script when it finishes
trap "rm -f $0; exit $exit_code;" EXIT
