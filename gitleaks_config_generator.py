""" Gitleaks Config Generator

This script reads the gitleaks global config which contains the regexes of the
secrets we look for and common whitelist for all the projects. Then, it reads
the .gitleaks.toml file of a specific project which contains the known secrets
that should be ignored and any other project specific rule. Finally, it merges
the two config files to create the final one that will be passed to gitleaks.
"""

import sys
import copy
from pathlib import Path

import toml


def main():
    final_config = get_final_config('global_config.toml', '.gitleaks.toml')
    print(toml.dumps(final_config))


def get_final_config(global_config_path, local_config_path):
    if local_config_path != '' and Path(local_config_path).exists():
        final_config = merge_config(global_config_path, local_config_path)
        return final_config
    else:
        global_config = open_toml(global_config_path)
        return global_config


def merge_config(global_config_path, local_config_path):
    global_config = open_toml(global_config_path)
    repo_config = open_toml(local_config_path)
    final_config = copy.deepcopy(global_config)

    # Making the script backwards compatible with local configs that use
    # the previous config file format
    if "whitelist" in repo_config:
        allowlist_key = "whitelist"
    else:
        allowlist_key = "allowlist"

    for section, values in repo_config[allowlist_key].items():
        if section == "description":
            continue

        for value in values:
            if section not in final_config["allowlist"]:
                final_config["allowlist"][section] = [value]
            elif value not in final_config["allowlist"][section]:
                final_config["allowlist"][section].append(value)

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
