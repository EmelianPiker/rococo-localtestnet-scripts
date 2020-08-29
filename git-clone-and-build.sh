#!/bin/sh
test -f localtestnet.sh || exit
top=$PWD
cd ..

function clone_and_build() {
	if [ ! -d $1 ]; then
		git clone $2
		pushd $1
			git checkout $3
			ln -s $top/Makefile .
			ln -s $top/shell.nix .
			ln -s $top/nix-env.sh .
			make || exit
		popd
	fi
}

clone_and_build iroha     https://github.com/EmelianPiker/iroha ae9f93f0
clone_and_build polkadot  https://github.com/paritytech/polkadot fd4b176f
clone_and_build parachain https://github.com/EmelianPiker/substrate-iroha-bridge-node 5eb92b17

