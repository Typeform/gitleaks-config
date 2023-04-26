# gitleaks-config

[![Build Status](https://github.com/Typeform/gitleaks-config/actions/workflows/ci.yaml/badge.svg)](https://github.com/Typeform/gitleaks-config/actions/workflows/ci.yaml)
[![Docker Image](https://img.shields.io/badge/ECR-docker%20image-blue?logo=docker)](https://gallery.ecr.aws/typeform/gitleaks-config)

This repository contains a customized [gitleaks](https://github.com/zricethezav/gitleaks) configuration, a Python script to merge `gitleaks` configurations, and a Dockerfile to combine both things and use it in a CI/CD environment.

## The customized configuration

The customized configuration (`global_config.toml`) aims to detect:
* Common API keys such as AWS Secret keys, Slack tokens, Stripe tokens, etc.
* Hardcoded credentials in Go, JavaScript, TypeScript, PHP, YAML, and HCL files. For each language there's a custom regular expression so the detection can be more granular and reduce the false positives

To avoid false positives the customized configuration (`global_config.toml`) skips the following:
* Common binaries such as `.jpg`, `.gif`, `.pdf`, etc.
* Unit test files for Go, JavaScript, and TypeScript
* Dependency manifest files for Go and NodeJS
* Go dependencies and NodeJS dependencies
* Test directories
* Lines that contain `test` in them


## Merging configurations

`gitleaks_config_generator.py` is a Python script that merges a user-provided configuration named `.gitleaks.toml` with `global_configuration.toml`. This is useful for repositories that want their commits and PRs scanned but they want to skip certain files, paths, or commits due to some false positives

The file `.gitleaks.toml` must look something like this:
```yaml
[allowlist]
  commits = [ "somecommitID", "anothercommitID"]
  files = [ '''go\.(mod|sum)''', "file-with-some-tests.js"]
  paths = [ '''templates\/(en|es)''', "mock/server"]
  regexes = ['''auth_test''']

# Notice the difference between using regular expressions '''regexp''' and
# exact matches "exactMatch"
```


On the same directory where `.gitleaks.toml` is located, run the following to obtain the merged configuration on `STDOUT`:
```bash
python3 gitleaks_config_generator.py
```

## Docker image

The docker image can be used to run `gitleaks` on a CI/CD environment (e.g. Github Actions) and to, for example, block PRs that contain credentials or secrets.

A simple example of CI/CD integration would be to run the following Bash code on every new PR:
```bash
# Merge repo's local config
final_config="/tmp/gitleaks_config.toml"
docker container run --rm -v repo_to_be_scanned/.gitleaks.toml:/app/.gitleaks.toml \
    public.ecr.aws/typeform/gitleaks-config > $final_config

# Run gitleaks with the generated config
docker container run --rm --name=gitleaks \
    -v $final_config:$final_config \
    -v repo_to_be_scanned:/tmp/repo_to_be_scanned \
    zricethezav/gitleaks:latest --config-path=$final_config --path=/tmp/$repo_name --verbose
```

## Contributing

Did you spot an error? Do you think something could be improved? We appreciate your help and contributions!

First, we recommend you open an issue and discuss your suggested change. Then you can fork and clone this repo and submit your changes through a Pull Request to this repo.

Before submitting the Pull Request please check that the code works on your local machine:
```bash
make test
```

We use [semantic-release](https://github.com/semantic-release/semantic-release) to automatically release new versions. Please use [Semantic Commit Messages](https://github.com/angular/angular/blob/master/CONTRIBUTING.md#-commit-message-format) so the releases are properly executed.
