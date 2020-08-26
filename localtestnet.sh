#!/bin/sh
test_names="alice bob"

relay_nodes_count=2

parachains="200"
parachain_nodes_count=1
parachain_collators_count=4

dir=`dirname $PWD`
iroha="$dir/iroha"
polkadot="$dir/polkadot"
chain_json="$polkadot/rococo-custom.json"
parachain="$dir/substrate-parachain-template"
logdir_pattern="/tmp/iroha-rococo-localtestnet-logs-XXXXXXXX"

# Empty values
relay_nodes=""
parachain_collators=""

function get_test_name() {
	echo $test_names | fmt -w 1 | awk "NR == `expr $1 + 1` { print \$0 }"
}

function check_dirs_and_files() {
	test -d $iroha      || exit 1
	test -d $polkadot   || exit 1
	test -f $chain_json || exit 1
}

function create_log_dir() {
	log=`mktemp -u $logdir_pattern`
	mkdir -p $log
	echo "Rococo localtestnet logdir is: $log"
}

function add_path() {
	PATH="$1/target/release:$PATH"
}

function start_relay_node() {
	wsport=`expr $1 + 9944`
	port=`expr $1 + 30333`
	test_name=`get_test_name $1`
	prefix=$log/relay_node
	localid=${prefix}_$1.localid
	logfile=${prefix}_$1.log
	bootnodes=""
	if [ "$relay_nodes" != "" ]
	then
		bootnodes="--bootnodes $relay_nodes"
	fi
	sh -c "polkadot \
		  --chain $chain_json \
	          --tmp \
	          --ws-port $wsport \
	          --port $port \
	          --$test_name \
	          $bootnodes 2>&1" | \
	    awk "BEGIN { a=1 }
		 /Local node identity is: /
		 { if (a==1) { print \$8 > \"$localid\"; fflush() }; a=0 }
		 { print \$0; fflush() }" > $logfile &
	while [ ! -f $localid ]
	do
		sleep 0.1
	done
	echo "Relay node $1 with is running"
	relay_nodes="$relay_nodes /ip4/127.0.0.1/tcp/$port/p2p/`cat $localid`"
}

function start_parachain_collator() {
	wsport=`expr $1 + 19944`
	port=`expr $1 + 31333`
	test_name=`get_test_name $1`
	prefix=$log/parachain_$2_collator
	localid=${prefix}_$1.localid
	logfile=${prefix}_$1.log
	relaychain_bootnodes=""
	if [ "$relay_nodes" != "" ]
	then
		relaychain_bootnodes="--bootnodes $relay_nodes"
	fi
	parachain_bootnodes=""
	if [ "$parachain_collators" != "" ]
	then
		parachain_bootnodes="--bootnodes $parachain_collators"
	fi
	sh -c "parachain-collator \
		  --tmp \
		  --validator \
		  --ws-port $wsport \
		  --port $port \
		  --parachain-id $2 \
		  $parachain_bootnodes \
		  -- --chain $chain_json \
	          $relaychain_bootnodes 2>&1" | \
	    awk "BEGIN { a=1 }
		 /Local node identity is: /
		 { if (a==1) { print \$8 > \"$localid\"; fflush() }; a=0 }
		 { print \$0; fflush() }" > $logfile &
	while [ ! -f $localid ]
	do
		sleep 0.1
	done
	echo "Parachain $2 collator $1 with is running"
	parachain_collators="$parachain_collators /ip4/127.0.0.1/tcp/$port/p2p/`cat $localid`"
}


check_dirs_and_files
create_log_dir

add_path $iroha
add_path $polkadot
add_path $parachain

for relay_node_number in `seq 1 $relay_nodes_count`
do
	start_relay_node `expr $relay_node_number - 1`
done

for parachain_id in $parachains
do
	for parachain_collator_number in `seq 1 $parachain_collators_count`
	do
		start_parachain_collator `expr $parachain_collator_number - 1` $parachain_id
	done
done

wait


