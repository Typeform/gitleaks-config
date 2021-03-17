#!/bin/sh
set -e
# Run gitleaks on each file of the given directory $1
# $2 is the value of the expected exit code of gitleaks execution (i.e. secrets detection expected or not)
# $3 is the error message to be shown when gitleaks' exit code is different than expected
run_tests () {
    for f in ${1}/*; do
        # Create a new empty repo for each test file
        repo_dir="${PWD}/test_repo"
        mkdir ${repo_dir} && cd ${repo_dir} && git init && cd ..

        # Copy and git commit the test file
        cp -r ${f} ${repo_dir}
        cd ${repo_dir} && git add . && git commit -m 'test' && cd ..

        # Run gitleaks on the repo
        echo "Scanning ${f}"
        run_gitleaks ${PWD}/${final_config} ${repo_dir}
        exit_code=$?

        if [ ${exit_code} -ne ${2} ]; then
            echo "\033[0;31m${3} ${f}\033[0m"
            tests_failed=1
        fi

        # Remove the git repo
        rm -rf ${repo_dir}
    done
}

# Execute gitleaks with a given configuration file $1 in a given repo $2
run_gitleaks () {
    run_gitleaks="docker container run --rm --name=gitleaks \
        -v ${1}:/tmp/gitleaks_config.toml \
        -v ${2}:/tmp/repo \
        quay.io/typeform/gitleaks --config=/tmp/gitleaks_config.toml --repo=/tmp/repo --verbose"
    $run_gitleaks
}

# Generate configuration
final_config="test_gitleaks_config.toml"
gitleaks_config_container="quay.io/typeform/gitleaks-config"

docker container run --rm $gitleaks_config_container \
    python gitleaks_config_generator.py > $final_config

tests_failed=0
set +e
# Run tests expecting to detect a secret
code_with_secrets_dir="${PWD}/test_data/secrets"
run_tests ${code_with_secrets_dir} 1 "Expecting to detect secrets in"

# Run tests expecting to not detect a secret
code_with_no_secrets_dir="${PWD}/test_data/no_secrets"
run_tests ${code_with_no_secrets_dir} 0 "Expecting to not detect secrets in"

# Clean up
rm ${final_config}

if [ ${tests_failed} -eq 0 ]; then
    echo "\033[0;32mTests passed\033[0m"
else
    echo "\033[0;31mTests failed\033[0m"
fi

exit ${tests_failed}
