#!/bin/sh

CHAIN_DIR=/home/heighliner/.evmosd

if [ ! -d $CHAIN_DIR ]; then

  # Initialize config
  evmosd init chain-node

  CONFIG_DIR=$CHAIN_DIR/config

  # Get Genesis JSON
  # Testnet
  wget -P ~/.evmosd/config https://snapshots.nodes.guru/evmos_9000-4/genesis.json

  # Get seeds
  # Testnet
  SEEDS=$(curl -sL "https://github.com/tharsis/testnets/raw/main/evmos_9000-4/seeds.txt" | paste -d, -s)
  PERSISTENT_PEERS=`curl -sL https://raw.githubusercontent.com/tharsis/testnets/main/evmos_9000-4/peers.txt | head -n 10 | awk '{print $1}' | paste -s -d, -`


  MINIMUM_GAS_PRICE="0.025atevmos"

  # config.toml
  CONFIG_FILE=$CONFIG_DIR/config.toml
  sed -i '/^indexer = .*/ s//indexer = "kv"/' $CONFIG_FILE
  sed -i "/^persistent_peers = .*/ s//persistent_peers = \"$PERSISTENT_PEERS\"/" $CONFIG_FILE
  sed -i "/^external_address = .*/ s//external_address = \"$(curl -s ifconfig.me):26656\"/" $CONFIG_FILE
  sed -i '/^laddr = "tcp:\/\/127.0.0.1:26657"/ s//laddr = "tcp:\/\/0.0.0.0:26657"/' $CONFIG_FILE
  sed -i '/^max_num_outbound_peers = .*/ s//max_num_outbound_peers = 20/' $CONFIG_FILE
  sed -i '/^max_num_inbound_peers = .*/ s//max_num_inbound_peers = 20/' $CONFIG_FILE
  sed -i "/^seeds = .*/ s//seeds = \"$SEEDS\"/" $CONFIG_FILE
  sed -i '/^cors_allowed_origins = .*/ s//cors_allowed_origins = \["\*"\]/' $CONFIG_FILE

  # app.toml
  APP_FILE=$CONFIG_DIR/app.toml
  sed -i '/^pruning = .*/ s//pruning = "nothing"/' $APP_FILE
  # sed -i '/^pruning-keep-recent = .*/ s//pruning-keep-recent = "100000"/' $APP_FILE
  # sed -i '/^pruning-keep-every = .*/ s//pruning-keep-every = "0"/' $APP_FILE
  # sed -i '/^pruning-interval = .*/ s//pruning-interval = "17"/' $APP_FILE
  sed -i "/^minimum-gas-prices = .*/ s//minimum-gas-prices = \"$MINIMUM_GAS_PRICE\"/" $APP_FILE
  sed -i "/^snapshot-interval = .*/ s//snapshot-interval = 1000/" $APP_FILE

  # Testnet
  LATEST_SNAPSHOT=$(curl -s https://snapshots.stakingcare.com/evmos/testnet/ | egrep -o ">evmos.*tar" | tr -d ">" | tail -n1)
  wget -O - "https://snapshots.stakingcare.com/evmos/testnet/$LATEST_SNAPSHOT" | tar xv -C $CHAIN_DIR
fi

# sleep 30

evmosd start
