#!/bin/sh

relay_nodes=2
parachain_nodes=1
parachain_collators=1

dir=`dirname $PWD`
iroha="$dir/iroha"
polkadot="$dir/polkadot"
chain_json="$polkadot/rococo-custom.json"

function check_dirs_and_files() {
	test -d $iroha      || exit 1
	test -d $polkadot   || exit 1
	test -f $chain_json || exit 1
}

function add_path() {
	PATH="$PATH:$1/target/release"
}

check_dirs_and_files

add_path $iroha
add_path $polkadot

