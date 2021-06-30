#!/usr/bin/env bash

set -o errexit -o pipefail

# Executes cleanup function at script exit.
trap cleanup EXIT

cleanup() {
  # Kill the ganache instance that we started (if we started one and if it's still running).
  if [ -n "$ganache_pid" ] && ps -p $ganache_pid > /dev/null; then
    kill -9 $ganache_pid
  fi
}

ganache_running() {
  netcat -z localhost 8545
}

start_ganache() {
  local accounts=(
    # 10 accounts with balance 1M ether, needed for high-value tests.
    --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501200,1000000000000000000000000"
    --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501201,1000000000000000000000000"
    --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501202,1000000000000000000000000"
    --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501203,1000000000000000000000000"
    --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501204,1000000000000000000000000"
    --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501205,1000000000000000000000000"
    --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501206,1000000000000000000000000"
    --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501207,1000000000000000000000000"
    --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501208,1000000000000000000000000"
    --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501209,1000000000000000000000000"
    # 3 accounts to be used for GSN matters.
    --account="0x956b91cb2344d7863ea89e6945b753ca32f6d74bb97a59e59e04903ded14ad00,1000000000000000000000000"
    --account="0x956b91cb2344d7863ea89e6945b753ca32f6d74bb97a59e59e04903ded14ad01,1000000000000000000000000"
    --account="0x956b91cb2344d7863ea89e6945b753ca32f6d74bb97a59e59e04903ded14ad02,1000000000000000000000000"
  )

  npx ganache-cli --gasLimit 0xfffffffffff --port 8545 "${accounts[@]}" > /dev/null &

  ganache_pid=$!

  echo "Waiting for ganache to launch on port 8545..."

  while ! ganache_running; do
    sleep 0.1 # wait for 1/10 of the second before check again
  done

  echo "Ganache launched!"
}

start_ganache

vertigo run --network development --truffle-location node_modules/.bin/truffle
