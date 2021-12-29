#!/bin/sh
set -e

image_name = ${ECR_REGISTRY}/gitleaks-config

# Generate configuration
final_config="${PWD}/global_config.toml"
repo_dir="${PWD}/test_repo"

cleanup () {
    echo "Cleaning up..."
    rm -f ${repo_dir}
}

trap cleanup EXIT

# Run gitleaks on each file of the given directory $1
# $2 is the value of the expected exit code of gitleaks execution (i.e. secrets detection expected or not)
# $3 is the error message to be shown when gitleaks' exit code is different than expected
run_tests () {
    for f in ${1}/*; do
        # Create a new empty repo for each test file
        mkdir -p ${repo_dir}
        cd ${repo_dir}
        git init
        cd ..

        # Copy and git commit the test file
        cp -r ${f} ${repo_dir}
        cd ${repo_dir}
        git add .
        git -c user.name='Automated Tests' -c user.email='none@somewhere.org' commit -m 'test'
        cd ..

        # Run gitleaks on the repo
        echo "Scanning ${f}"
        run_gitleaks ${final_config} ${repo_dir}
        exit_code=$?

        if [ ${exit_code} -ne ${2} ]; then
            echo "\033[0;31m${3} ${f}\033[0m"
            tests_failed=1
        fi

        rm -rf ${repo_dir}
    done
}

# Execute gitleaks with a given configuration file $1 in a given repo $2
run_gitleaks () {
    run_gitleaks="docker container run --rm --name=gitleaks \
        -v ${1}:/tmp/gitleaks_config.toml \
        -v ${2}:/tmp/repo \
        ${image_name} --config=/tmp/gitleaks_config.toml --repo=/tmp/repo --verbose"
    $run_gitleaks
}

tests_failed=0
set +e
# Run tests expecting to detect a secret
code_with_secrets_dir="${PWD}/test/sample_files/secrets"
run_tests ${code_with_secrets_dir} 1 "Expecting to detect secrets in"

# Run tests expecting to not detect a secret
code_with_no_secrets_dir="${PWD}/test/sample_files/no_secrets"
run_tests ${code_with_no_secrets_dir} 0 "Expecting to not detect secrets in"

if [ ${tests_failed} -eq 0 ]; then
    echo "\033[0;32mTests passed\033[0m"
else
    echo "\033[0;31mTests failed\033[0m"
fi

exit ${tests_failed}
