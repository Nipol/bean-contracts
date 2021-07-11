#!/usr/bin/env bash

# Exit script as soon as a command fails.
set -o errexit

log() {
  # Print to stderr to prevent this from being 'returned'
  echo "$@" > /dev/stderr
}

prompt_otp() {
  log -n "Enter npm 2FA token: "
  read -r otp
  echo "$otp"
}

log "Publishing @beandao/contracts on npm"
cd contracts
env ALREADY_COMPILED= \
    # npm publish --tag "$dist_tag" --otp "$(prompt_otp)"
    npm publish --otp "$(prompt_otp)"
cd ..
