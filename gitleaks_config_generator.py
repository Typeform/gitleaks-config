""" Gitleaks Config Generator

This script reads the gitleaks global config which contains the regexes of the
secrets we look for and common whitelist for all the projects. Then, it reads
the .secretsignore file of a specific project which contains the known secrets
that should be ignored and any specific whitelisting rule. Finally, it merges
the two config files to create the final one that will be passed to gitleaks.
"""

import sys
import copy
from pathlib import Path

import toml


def main():
    final_config = get_final_config('global_config.toml', '.secretsignore')
    print(toml.dumps(final_config))


def get_final_config(global_config_path, secretsignore_path):
    if secretsignore_path != '' and Path(secretsignore_path).exists():
        final_config = merge_config(global_config_path, secretsignore_path)
        return final_config
    else:
        global_config = open_toml(global_config_path)
        return global_config


def merge_config(global_config_path, secretsignore_path):
    global_config = open_toml(global_config_path)
    repo_config = open_toml(secretsignore_path)
    final_config = copy.deepcopy(global_config)

    for section, values in repo_config["whitelist"].items():
        for value in values:
            if value not in final_config["whitelist"][section]:
                final_config["whitelist"][section].append(value)

    return final_config


def open_toml(path):
    try:
        return toml.load(path)
    except TypeError:
        print(f"Error opening the {path} file.", file=sys.stderr)
    except toml.TomlDecodeError:
        print(f"Error decoding the {path} file.", file=sys.stderr)


if __name__ == "__main__":
    main()
