#!/bin/sh

CHAIN_DIR=/home/heighliner/.omniflixhub

if [ ! -d $CHAIN_DIR ]; then
  CONFIG_DIR=$CHAIN_DIR/config
  # Initialize config
  omniflixhubd init chain-node

  # Get Genesis JSON
  wget -O $CONFIG_DIR/genesis.json https://raw.githubusercontent.com/OmniFlix/mainnet/main/omniflixhub-1/genesis.json

  PERSISTENT_PEERS="0a60b588671a5f1d1a524a66e86dbe40c81bd448@185.216.203.136:26656,55c6e002e769a752e1c80266e06afb5efbfc823c@38.242.206.186:26656,b10e09b559eb14d4dc07d43474ca0a1560391414@185.252.232.189:26656,a2077dce2d62cdcb8dc454f8eaef0e86846496ea@65.108.135.182:26656,c7f8c700f673cb586cebdcf85da3479724fa6988@65.108.128.241:26716,bc54943776dcbfbd77c5e2d6fa37cd663bef49cb@95.217.226.95:26099,c7ac940531a300dd6ae18222a1abb702241c036d@38.242.216.139:26656,2f635cc803e675c9123673afdb36344b81cdf792@65.108.217.3:26656,27c23bf7aa52b6623c3ae8b8e35ccf45a7d165b1@65.108.147.75:26656,0d9d7448727e2449d52f15b6c635022e1f10c0e7@142.132.196.251:56656,4fef00755591e8034ce1d47ce01ca6fd7f173d52@23.88.102.74:26656,2016d7a7ce3b35dbf7f9919af286b91b967639c1@45.56.114.201:26656,9fef14df52a2fbe66625951d07c1779089136c56@65.108.64.67:26656,9988a27fb55dfd01bf164fc71293ccd160384f2b@65.108.66.103:26656,5f95b51ddb4cb23a1e4607a58285d733dd004d7b@38.146.3.115:26656,438300cc6806eef0397bf9235f49e5eabd70e5da@95.217.72.158:26656,ff22b5928fe9beac8624fcb511e0ec20bb633193@34.148.89.98:26656,d8a0e887886546d4e7e2729735c605f3252a2201@34.148.204.54:26656,b5bcb5b60096ceb16be8d29c37f3962538adef7e@34.148.101.4:26656"
  MINIMUM_GAS_PRICE="0.001uflix"

  # config.toml
  CONFIG_FILE=$CONFIG_DIR/config.toml
  sed -i '/^indexer = .*/ s//indexer = "null"/' $CONFIG_DIR/config.toml
  sed -i "/^persistent_peers = .*/ s//persistent_peers = \"$PERSISTENT_PEERS\"/" $CONFIG_FILE
  sed -i "/^external_address = .*/ s//external_address = \"$(curl -s ifconfig.me):26656\"/" $CONFIG_FILE
  sed -i '/^max_num_inbound_peers = .*/ s//max_num_inbound_peers = 80/' $CONFIG_FILE
  sed -i '/^max_num_outbound_peers = .*/ s//max_num_outbound_peers = 80/' $CONFIG_FILE

  # app.toml
  APP_FILE=$CONFIG_DIR/app.toml
  sed -i '/^pruning = .*/ s//pruning = "custom"/' $APP_FILE
  sed -i '/^pruning-keep-recent = .*/ s//pruning-keep-recent = "100"/' $APP_FILE
  sed -i '/^pruning-keep-every = .*/ s//pruning-keep-every = "0"/' $APP_FILE
  sed -i '/^pruning-interval = .*/ s//pruning-interval = "10"/' $APP_FILE
  sed -i "/^minimum-gas-prices = .*/ s//minimum-gas-prices = \"$MINIMUM_GAS_PRICE\"/" $APP_FILE
  sed -i "/^snapshot-interval = .*/ s//snapshot-interval = 0/" $APP_FILE
fi

# sleep 30

omniflixhubd start
