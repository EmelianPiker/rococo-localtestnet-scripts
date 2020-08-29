.PHONY: build

RUN := $(shell which nix-shell > /dev/null && echo 'eval `cat ./nix-env.sh`; nix-shell --run ' || echo 'sh -c ')

build:
	${RUN} "cargo build --release"

