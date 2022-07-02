CHAIN_DIR=/home/heighliner/.sentinelhub
if [ ! -d $CHAIN_DIR ]; then
  CONFIG_DIR=$CHAIN_DIR/config
  # Initialize config
  CHAIN_ID=sentinelhub-2
  sentinelhub init chain-node

  NET_URL=https://raw.githubusercontent.com/sentinel-official/networks/main/$CHAIN_ID

  # Get Genesis JSON
  curl -o genesis.zip $NET_URL/genesis.zip
  unzip -o genesis.zip -d $CONFIG_DIR
  rm genesis.zip

  PERSISTENT_PEERS=$(curl -s "$NET_URL/persistent_peers.txt")
  SEEDS=$(curl -s "$NET_URL/seeds.txt")
  MINIMUM_GAS_PRICE="0.1udvpn"

  # config.toml
  CONFIG_FILE=$CONFIG_DIR/config.toml
  sed -i '/^indexer = .*/ s//indexer = "null"/' $CONFIG_FILE
  sed -i "/^persistent_peers = .*/ s//persistent_peers = \"$PERSISTENT_PEERS\"/" $CONFIG_FILE
  sed -i "/^seeds = .*/ s//seeds = \"$SEEDS\"/" $CONFIG_FILE
  sed -i "/^external_address = .*/ s//external_address = \"$(curl -s ifconfig.me):26656\"/" $CONFIG_FILE
  sed -i '/^max_num_inbound_peers = .*/ s//max_num_inbound_peers = 80/' $CONFIG_FILE
  sed -i '/^max_num_outbound_peers = .*/ s//max_num_outbound_peers = 80/' $CONFIG_FILE
  sed -i '/^laddr = "tcp:\/\/127.0.0.1:26657"/ s//laddr = "tcp:\/\/0.0.0.0:26657"/' $CONFIG_FILE

  # app.toml
  APP_FILE=$CONFIG_DIR/app.toml
  sed -i '/^pruning = .*/ s//pruning = "custom"/' $APP_FILE
  sed -i "/^pruning-keep-recent = .*/ s//pruning-keep-recent = \"100\"/" $APP_FILE
  sed -i "/^pruning-keep-every = .*/ s//pruning-keep-every = \"0\"/" $APP_FILE
  sed -i "/^pruning-interval = .*/ s//pruning-interval = \"10\"/" $APP_FILE
  sed -i "/^minimum-gas-prices = .*/ s//minimum-gas-prices = \"$MINIMUM_GAS_PRICE\"/" $APP_FILE
  sed -i "/^snapshot-interval = .*/ s//snapshot-interval = 0/" $APP_FILE

  rm -rf $CHAIN_DIR/data/; \
  mkdir -p $CHAIN_DIR/data/; \
  cd $CHAIN_DIR/data/

  SNAP_NAME=$(curl -s http://135.181.60.250:8083/sentinel/ | egrep -o ">sentinelhub-2.*tar" | tr -d ">"); \
  wget -O - http://135.181.60.250:8083/sentinel/${SNAP_NAME} | tar xf -

fi

# sleep 30

sentinelhub start --x-crisis-skip-assert-invariants
