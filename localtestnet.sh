#!/bin/sh
test_names="alice bob"

relaychain_nodes_count=2

parachains="200"
parachain_fullnodes_count=2
parachain_collators_count=4

dir=`dirname $PWD`
iroha="$dir/iroha"
polkadot="$dir/polkadot"
chain_json="$polkadot/rococo-custom.json"
parachain="$dir/substrate-parachain-template"
logdir_pattern="/tmp/iroha-rococo-localtestnet-logs-XXXXXXXX"

# Empty values
relaychain_nodes=""
parachain_nodes=""

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

function start_relaychain_node() {
	wsport=`expr $1 + 9944`
	port=`expr $1 + 30333`
	test_name=`get_test_name $1`
	prefix=$log/relaychain_node
	localid=${prefix}_$1.localid
	logfile=${prefix}_$1.log
	bootnodes=""
	if [ "$relay_nodes" != "" ]
	then
		bootnodes="--bootnodes $relaychain_nodes"
	fi
	sh -c "exec polkadot \
		  --chain $chain_json \
	          --tmp \
	          --ws-port $wsport \
	          --port $port \
	          --$test_name \
	          $bootnodes 2>&1" | \
	    awk "BEGIN { a=1 }
		 /Local node identity is: /{ if (a) {
		   print \$8 > \"$localid\"; fflush(); a=0 } }
		 { print \$0; fflush() }" > $logfile &
	while [ ! -f $localid ]
	do
		sleep 0.1
	done
	echo "Relaychain node $1 is running"
	relaychain_nodes="$relaychain_nodes /ip4/127.0.0.1/tcp/$port/p2p/`cat $localid`"
}

function start_parachain_fullnode() {
	wsport=`expr $1 + 19944`
	port=`expr $1 + 31333`
	test_name=`get_test_name $1`
	prefix=$log/parachain_$2_fullnode_$1
	localid=$prefix.localid
	logfile=$prefix.log
	relaychain_bootnodes=""
	if [ "$relaychain_nodes" != "" ]
	then
		relaychain_bootnodes="--bootnodes $relaychain_nodes"
	fi
	parachain_bootnodes=""
	if [ "$parachain_nodes" != "" ]
	then
		parachain_bootnodes="--bootnodes $parachain_nodes"
	fi
	sh -c "parachain-collator \
		  --tmp \
		  --ws-port $wsport \
		  --port $port \
		  --parachain-id $2 \
		  $parachain_bootnodes \
		  -- --chain $chain_json \
	          $relaychain_bootnodes 2>&1" | \
	    awk "BEGIN { a=1 }
		 /Local node identity is: /{ if (a) {
		   print \$8 > \"$localid\"; fflush(); a=0 } }
		 { print \$0; fflush() }" > $logfile &
	while [ ! -f $localid ]
	do
		sleep 0.1
	done
	echo "Parachain $2 fullnode $1 is running"
	parachain_nodes="$parachain_nodes /ip4/127.0.0.1/tcp/$port/p2p/`cat $localid`"
}

function start_parachain_collator() {
	wsport=`expr $1 + 29944`
	port=`expr $1 + 32333`
	test_name=`get_test_name $1`
	prefix=$log/parachain_$2_collator_$1
	localid=$prefix.localid
	logfile=$prefix.log
	relaychain_bootnodes=""
	if [ "$relaychain_nodes" != "" ]
	then
		relaychain_bootnodes="--bootnodes $relaychain_nodes"
	fi
	parachain_bootnodes=""
	if [ "$parachain_nodes" != "" ]
	then
		parachain_bootnodes="--bootnodes $parachain_nodes"
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
		 /Local node identity is: /{ if (a) {
		   print \$8 > \"$localid\"; fflush(); a=0 } }
		 { print \$0; fflush() }" > $logfile &
	while [ ! -f $localid ]
	do
		sleep 0.1
	done
	echo "Parachain $2 collator $1 is running"
	parachain_nodes="$parachain_nodes /ip4/127.0.0.1/tcp/$port/p2p/`cat $localid`"
}


check_dirs_and_files
create_log_dir

add_path $iroha
add_path $polkadot
add_path $parachain

for relaychain_node_number in `seq 1 $relaychain_nodes_count`
do
	start_relaychain_node `expr $relaychain_node_number - 1`
done

for parachain_id in $parachains
do

	for parachain_fullnode_number in `seq 1 $parachain_fullnodes_count`
	do
		start_parachain_fullnode `expr $parachain_fullnode_number - 1` $parachain_id
	done

	for parachain_collator_number in `seq 1 $parachain_collators_count`
	do
		start_parachain_collator `expr $parachain_collator_number - 1` $parachain_id
	done

done

wait


