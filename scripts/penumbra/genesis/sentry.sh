#!/bin/sh
CHAIN_DIR=/home/heighliner/.tendermint

if [ ! -d $CHAIN_DIR ]; then
  # Initialize config
  tendermint init full --home $CHAIN_DIR

  CONFIG_DIR=$CHAIN_DIR/config

  # Get Genesis JSON
  curl -X GET "http://testnet.penumbra.zone:26657/genesis" -H "accept: application/json" | jq '.result.genesis' > $CONFIG_DIR/genesis.json

  PERSISTENT_PEERS="0247232abf43ca581a68aca7d574b8831777556a@testnet.penumbra.zone:26656"

  # config.toml
  CONFIG_FILE=$CONFIG_DIR/config.toml
  sed -i '/^indexer = .*/ s//indexer = "null"/' $CONFIG_FILE
  sed -i "/^persistent-peers = .*/ s//persistent-peers = \"$PERSISTENT_PEERS\"/" $CONFIG_FILE
  sed -i "/^external-address = .*/ s//external-address = \"$(curl -s ifconfig.me):26656\"/" $CONFIG_FILE
  sed -i '/^max-num-inbound_peers = .*/ s//max-num-inbound_peers = 80/' $CONFIG_FILE
  sed -i '/^laddr = "tcp:\/\/127.0.0.1:26657"/ s//laddr = "tcp:\/\/0.0.0.0:26657"/' $CONFIG_FILE
fi

# sleep 30

tendermint start --proxy-app=tcp://localhost:26658
