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

import tomlkit


def main():
    config_file = 'global_config_legacy.toml' # config file for gitleaks versions previous to v8
    if '--v8-config' in sys.argv:
        config_file = 'global_config.toml'

    final_config = get_final_config(config_file, '.gitleaks.toml')
    print(tomlkit.dumps(final_config))


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

    # Temporary backwards compatibility with gitleaks v7 until all repos
    # have updated their .gitleaks.toml files
    v8_config = False
    if global_config_path == "global_config.toml":
        v8_config = True

    # Making the script backwards compatible with local configs that use
    # the previous config file format
    if "whitelist" in repo_config:
        allowlist_key = "whitelist"
    else:
        allowlist_key = "allowlist"

    for section, values in repo_config[allowlist_key].items():
        if section == "description":
            continue

        # This will autocorrect .gitleaks.toml files that have a v7 config
        # file format but requesting a v8 config file format
        section_key = section
        if v8_config and section == "files":
            section_key = "paths"

        for value in values:
            if section_key not in final_config["allowlist"]:
                final_config["allowlist"][section_key] = [value]
            elif value not in final_config["allowlist"][section_key]:
                final_config["allowlist"][section_key].append(value)

    return final_config


def open_toml(path):
    try:
        with open(path, 'r') as file:
            return tomlkit.load(file)
    except Exception as e:
        print(f"Error opening the {path} file: {e}", file=sys.stderr)


if __name__ == "__main__":
    main()
