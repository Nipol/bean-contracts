#!/usr/bin/env zsh

set -e

sudo chown node node_modules \
    && sudo mkdir -p /home/node/.ssh \
     && sudo cp -r /home/node/.ssh-localhost/* /home/node/.ssh \
     && sudo chmod 707 /home/node/.ssh \
     && sudo chmod 606 /home/node/.ssh/* \
     && solc-select install $SOLC_VERSION \
     && solc-select use $SOLC_VERSION \
     && foundryup \
     && npm install
