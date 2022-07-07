#!/bin/sh

CHAIN_DIR=/home/heighliner/.sommelier

if [ ! -d $CHAIN_DIR ]; then
  CONFIG_DIR=$CHAIN_DIR/config
  # Initialize config
  sommelier init chain-node

  # Get Genesis JSON
  wget -O $CONFIG_DIR/genesis.json https://github.com/PeggyJV/SommelierNetwork/raw/main/genesis.json

  PERSISTENT_PEERS="e1d1dd22a63b1899ac51c8c96416f77c8ef98231@sommelier.tendermint.cloud:26656,a96d69179e4b72f728b9dd4dbe40400701515fee@80.64.208.51:26656,759a61eade50cb48e2a6f974fab679096d1de916@34.127.107.137:26656,14ac13745a563876740b72637ab9a3539542fe2b@35.185.230.0:26656,bebf759f5706137168e3a7158e4495865a04cca9@34.83.151.60:26656,6533beebc826f84376e503bbc3265b07b26b9ad5@sommelier.standardcryptovc.com:26656,c94fd60124e3656df54ff965d178e36c760c195d@65.108.57.224:26656,65cc609f9ae965323bd03d1b84f7fa340e6b6c7d@51.38.52.210:36656,4ed70d91bd645e78a78fe6cd4d1973937bb739e1@51.91.67.48:36656,404e6b2176bf74018cfdeb275c21ce264d43c673@54.38.46.179:36656,c7334f0462cad3272f7d504f7a293fd2585165ef@35.215.30.79:26656,3dcf24ab4144ece91bc47e132a1b49964fe0d1f3@65.108.121.152:26656"
  MINIMUM_GAS_PRICE=""

  # config.toml
  CONFIG_FILE=$CONFIG_DIR/config.toml
  sed -i '/^max_num_inbound_peers = .*/ s//max_num_inbound_peers = 80/' $CONFIG_FILE
  sed -i '/^indexer = .*/ s//indexer = "kv"/' $CONFIG_FILE
  sed -i "/^persistent_peers = .*/ s//persistent_peers = \"$PERSISTENT_PEERS\"/" $CONFIG_FILE
  sed -i "/^external_address = .*/ s//external_address = \"$(curl -s ifconfig.me):26656\"/" $CONFIG_FILE
  sed -i '/^max_num_inbound_peers = .*/ s//max_num_inbound_peers = 80/' $CONFIG_FILE
  sed -i '/^laddr = "tcp:\/\/127.0.0.1:26657"/ s//laddr = "tcp:\/\/0.0.0.0:26657"/' $CONFIG_FILE
  sed -i '/^cors_allowed_origins = .*/ s//cors_allowed_origins = \["\*"\]/' $CONFIG_FILE

  # app.toml
  APP_FILE=$CONFIG_DIR/app.toml
  sed -i '/^pruning = .*/ s//pruning = "custom"/' $APP_FILE
  sed -i '/^pruning-keep-recent = .*/ s//pruning-keep-recent = "300000"/' $APP_FILE
  sed -i '/^pruning-keep-every = .*/ s//pruning-keep-every = "0"/' $APP_FILE
  sed -i '/^pruning-interval = .*/ s//pruning-interval = "17"/' $APP_FILE
  sed -i "/^minimum-gas-prices = .*/ s//minimum-gas-prices = \"$MINIMUM_GAS_PRICE\"/" $APP_FILE

  SNAPSHOT_INTERVAL=1000
  SNAPSHOT_KEEP_RECENT=2

  sed -i "/^snapshot-interval = .*/ s//snapshot-interval = $SNAPSHOT_INTERVAL/" $APP_FILE
  sed -i "/^snapshot-keep-recent = .*/ s//snapshot-keep-recent = $SNAPSHOT_KEEP_RECENT/" $APP_FILE
fi

# sleep 30

sommelier start
