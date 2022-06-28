#!/bin/sh
set -e

GITLEAKS_IMAGE="zricethezav/gitleaks"
GITLEAKS_VERSION="v8.8.8"

# Generate configuration
gitleaks_config="${PWD}/global_config.toml"

# Run gitleaks on each file of the given directory $1
# $2 is the value of the expected exit code of gitleaks execution (i.e. secrets detection expected or not)
# $3 is the error message to be shown when gitleaks' exit code is different than expected
run_tests () {
    for f in ${1}/*; do
        # Run gitleaks on the file to be tested
        echo "Scanning ${f}"
        run_gitleaks ${gitleaks_config} ${f}
        exit_code=$?

        if [ ${exit_code} -ne ${2} ]; then
            echo "\033[0;31m${3} ${f}\033[0m"
            tests_failed=1
        fi

    done
}

# Execute gitleaks with a given configuration file $1 in a given repo $2
run_gitleaks () {
    config_file_in_container="/tmp/gitleaks_config.toml"
    filename=$(basename ${2})
    scan_source="/tmp/${filename}"
    gitleaks_cmd="detect \
                    --config ${config_file_in_container} \
                    --source ${scan_source} \
                    --no-git \
                    --report-format json \
                    --verbose"
    run_gitleaks="docker container run --rm --name=gitleaks \
        -v ${1}:${config_file_in_container} \
        -v ${2}:${scan_source} \
        ${GITLEAKS_IMAGE}:${GITLEAKS_VERSION} ${gitleaks_cmd}"
    echo $run_gitleaks
    $run_gitleaks
}

tests_failed=0
set +e
# Run tests expecting to detect a secret
code_with_secrets_dir="${PWD}/sample_files/secrets"
run_tests ${code_with_secrets_dir} 1 "Expecting to detect secrets in"

# Run tests expecting to not detect a secret
code_with_no_secrets_dir="${PWD}/sample_files/no_secrets"
run_tests ${code_with_no_secrets_dir} 0 "Expecting to not detect secrets in"

if [ ${tests_failed} -eq 0 ]; then
    echo "\033[0;32mTests passed\033[0m"
else
    echo "\033[0;31mTests failed\033[0m"
fi

exit ${tests_failed}
