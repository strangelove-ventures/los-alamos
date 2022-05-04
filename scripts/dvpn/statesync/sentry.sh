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

              RPC_PEER=rpc.sentinel.smartnodes.one:26657

              STATUS=$(curl -s $RPC_PEER/status)

              LATEST_HEIGHT=$(echo $STATUS | jq -r '.result.sync_info.latest_block_height')
              LATEST_TIME=$(echo $STATUS | jq -r '.result.sync_info.latest_block_time')
              LATEST_TIME_SECONDS=$(date +%s -d "$(echo "${LATEST_TIME::-11}" |  sed 's/T/ /')")
              echo "Latest height: $LATEST_HEIGHT, time seconds: $LATEST_TIME_SECONDS"

              DELTA_BLOCKS=1000

              DELTA_HEIGHT=$(($LATEST_HEIGHT-$DELTA_BLOCKS))
              DELTA_HEIGHT_REQ=$(curl -s $RPC_PEER/block?height=$DELTA_HEIGHT)
              DELTA_HASH=$(echo $DELTA_HEIGHT_REQ | jq -r '.result.block_id.hash')

              TRUST_HEIGHT=$DELTA_HEIGHT
              TRUST_HASH=$DELTA_HASH

              RPC_SERVERS="$RPC_PEER,$RPC_PEER"
              PERSISTENT_PEERS=$(curl -s "$NET_URL/persistent_peers.txt")
              SEEDS=$(curl -s "$NET_URL/seeds.txt")
              MINIMUM_GAS_PRICE="0.1udvpn"

              # config.toml
              CONFIG_FILE=$CONFIG_DIR/config.toml
              sed -i '/^enable = false/ s//enable = true/' $CONFIG_FILE # enable state sync
              sed -i "/^trust_height = .*/ s//trust_height = $TRUST_HEIGHT/" $CONFIG_FILE
              sed -i "/^trust_hash = .*/ s//trust_hash = \"$TRUST_HASH\"/" $CONFIG_FILE
              sed -i "/^rpc_servers = .*/ s//rpc_servers = \"$RPC_SERVERS\"/" $CONFIG_FILE
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
           
            fi

            # sleep 30

            sentinelhub start --x-crisis-skip-assert-invariants
