#!/bin/sh

CHAIN_DIR=/home/heighliner/.kujira

if [ ! -d $CHAIN_DIR ]; then
  # Initialize config
  kujirad init chain-node

  CONFIG_DIR=$CHAIN_DIR/config

  # Get Genesis JSON
  wget -O $CONFIG_DIR/genesis.json https://raw.githubusercontent.com/Team-Kujira/networks/master/mainnet/kaiyo-1.json

  PERSISTENT_PEERS="635da0eabda2beea41af03f613c9ee242b81462d@52.54.117.83:26656,0f45ad954ac8a0674a73f1fbca5847650c245ba3@141.94.219.133:11756,ca0c3579d13b223044ff5c5b13e5262086c80b0b@173.212.229.120:11756,3c6e0c7b8be14ccf1717d84f3c11dcc1d2bfcba9@65.108.232.149:30095,1048e73299d435b6598245d246562efc62df002d@65.108.128.201:18656"
  SEEDS="5a70fdcf1f51bb38920f655597ce5fc90b8b88b8@136.244.29.116:41656,2c0be5d48f1eb2ff7bd3e2a0b5b483835064b85a@95.216.7.241:41001"
  MINIMUM_GAS_PRICE="0.00125ukuji"

  # config.toml
  CONFIG_FILE=$CONFIG_DIR/config.toml
  sed -i '/^indexer = .*/ s//indexer = "kv"/' $CONFIG_FILE
  sed -i "/^persistent_peers = .*/ s//persistent_peers = \"$PERSISTENT_PEERS\"/" $CONFIG_FILE
  sed -i "/^seeds = .*/ s//seeds = \"$SEEDS\"/" $CONFIG_FILE
  sed -i '/^timeout_commit = "5s"/ s//timeout_commit = "1500ms"/' $CONFIG_FILE
  sed -i "/^external_address = .*/ s//external_address = \"$(curl -s ifconfig.me):26656\"/" $CONFIG_FILE
  sed -i '/^laddr = "tcp:\/\/127.0.0.1:26657"/ s//laddr = "tcp:\/\/0.0.0.0:26657"/' $CONFIG_FILE
  sed -i '/^max_num_outbound_peers = .*/ s//max_num_outbound_peers = 80/' $CONFIG_FILE
  sed -i '/^cors_allowed_origins = .*/ s//cors_allowed_origins = \["\*"\]/' $CONFIG_FILE

  # app.toml
  APP_FILE=$CONFIG_DIR/app.toml
  sed -i "/^minimum-gas-prices = .*/ s//minimum-gas-prices = \"$MINIMUM_GAS_PRICE\"/" $APP_FILE

fi

# sleep 30

kujirad start --x-crisis-skip-assert-invariants
