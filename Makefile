all: build run

build:
	docker image build -t gitleaks-config .

run:
	docker container run --rm -v ${PWD}/.gitleaks.toml:/app/.gitleaks.toml gitleaks-config

test: build
	docker container run --rm -v ${PWD}/.gitleaks.toml:/app/.gitleaks.toml gitleaks-config \
		   python gitleaks_config_generator_tests.py
