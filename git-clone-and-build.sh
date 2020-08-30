#!/bin/sh
test -f localtestnet.sh || exit
top=$PWD
cd ..

function clone_and_build() {
	if [ ! -d $2 ]; then
		git clone $3
		mv `basename $3` $2
		pushd $2
			git checkout $4
			ln -s $top/misc/Makefile .
			ln -s $top/misc/shell.nix .
			ln -s $top/misc/nix-env.sh .
			make $1 || exit
		popd
	fi
}

clone_and_build yarn  api       https://github.com/polkadot-js/api 7ecd00a4
clone_and_build cargo iroha     https://github.com/EmelianPiker/iroha ae9f93f0
clone_and_build cargo polkadot  https://github.com/paritytech/polkadot fd4b176f
clone_and_build cargo parachain https://github.com/EmelianPiker/substrate-iroha-bridge-node 5eb92b17

