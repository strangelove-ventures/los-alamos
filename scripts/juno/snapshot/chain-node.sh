#!/bin/sh

CHAIN_DIR=/home/heighliner/.juno

if [ ! -d $CHAIN_DIR ]; then
  # Initialize config
  junod init chain-node

  CONFIG_DIR=$CHAIN_DIR/config

  # Get Genesis JSON
  wget -O $CONFIG_DIR/genesis.json https://github.com/CosmosContracts/mainnet/raw/main/juno-1/genesis.json

  PERSISTENT_PEERS="b1f46f1a1955fc773d3b73180179b0e0a07adce1@162.55.244.250:39656,7f593757c0cde8972ce929381d8ac8e446837811@178.18.255.244:26656,7b22dfc605989d66b89d2dfe118d799ea5abc2f0@167.99.210.65:26656,4bd9cac019775047d27f9b9cea66b25270ab497d@137.184.7.164:26656"
  SEEDS="2484353dab0b2c1275765b8ffa2c50b3b36158ca@seed-node.junochain.com:26656,ef2315d81caa27e4b0fd0f267d301569ee958893@juno-seed.blockpane.com:26656"
  MINIMUM_GAS_PRICE="0.0025ujuno"

  # config.toml
  CONFIG_FILE=$CONFIG_DIR/config.toml
  sed -i '/^indexer = .*/ s//indexer = "kv"/' $CONFIG_FILE
  sed -i "/^persistent_peers = .*/ s//persistent_peers = \"$PERSISTENT_PEERS\"/" $CONFIG_FILE
  sed -i "/^seeds = .*/ s//seeds = \"$SEEDS\"/" $CONFIG_FILE
  sed -i "/^external_address = .*/ s//external_address = \"$(curl -s ifconfig.me):26656\"/" $CONFIG_FILE
  sed -i '/^laddr = "tcp:\/\/127.0.0.1:26657"/ s//laddr = "tcp:\/\/0.0.0.0:26657"/' $CONFIG_FILE
  sed -i '/^max_num_outbound_peers = .*/ s//max_num_outbound_peers = 80/' $CONFIG_FILE
  sed -i '/^cors_allowed_origins = .*/ s//cors_allowed_origins = \["\*"\]/' $CONFIG_FILE

  # app.toml
  APP_FILE=$CONFIG_DIR/app.toml
  sed -i '/^pruning = .*/ s//pruning = "custom"/' $APP_FILE
  sed -i '/^pruning-keep-recent = .*/ s//pruning-keep-recent = "300000"/' $APP_FILE
  sed -i '/^pruning-keep-every = .*/ s//pruning-keep-every = "0"/' $APP_FILE
  sed -i '/^pruning-interval = .*/ s//pruning-interval = "17"/' $APP_FILE
  sed -i "/^minimum-gas-prices = .*/ s//minimum-gas-prices = \"$MINIMUM_GAS_PRICE\"/" $APP_FILE
  sed -i "/^snapshot-interval = .*/ s//snapshot-interval = 1000/" $APP_FILE

  wget -O - http://repository.activenodes.io/snapshots/juno-1_2022-03-01.tar.gz | tar -xz -C $CHAIN_DIR
fi

# sleep 30

junod start --x-crisis-skip-assert-invariants