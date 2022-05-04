            #!/bin/sh

            CHAIN_DIR=/home/heighliner/.osmosisd

            if [ ! -d $CHAIN_DIR ]; then
              # Initialize config
              osmosisd init chain-node

              mkdir -p $CHAIN_DIR/data/snapshots/metadata.db

              CONFIG_DIR=$CHAIN_DIR/config

              # Get Genesis JSON
              wget -O $CONFIG_DIR/genesis.json https://github.com/osmosis-labs/networks/raw/main/osmosis-1/genesis.json

              DELTA_BLOCKS=1500

              RPC_PEER=osmosis.strange.love:26657

              STATUS=$(curl -s $RPC_PEER/status)

              LATEST_HEIGHT=$(echo $STATUS | jq -r '.result.sync_info.latest_block_height')
              LATEST_TIME=$(echo $STATUS | jq -r '.result.sync_info.latest_block_time')
              LATEST_TIME_SECONDS=$(date +%s -d "$(echo "${LATEST_TIME::-11}" |  sed 's/T/ /')")
              echo "Latest height: $LATEST_HEIGHT, time seconds: $LATEST_TIME_SECONDS"
              
              DELTA_HEIGHT=$(($LATEST_HEIGHT-$DELTA_BLOCKS))
              DELTA_HEIGHT_REQ=$(curl -s $RPC_PEER/block?height=$DELTA_HEIGHT)
              DELTA_HASH=$(echo $DELTA_HEIGHT_REQ | jq -r '.result.block_id.hash')
              DELTA_TIME=$(echo $DELTA_HEIGHT_REQ | jq -r '.result.block.header.time')

              TRUST_HEIGHT=$DELTA_HEIGHT
              TRUST_HASH=$DELTA_HASH

              echo "Using trust height: $TRUST_HEIGHT and trust hash: $TRUST_HASH"

              #RPC_SERVERS="$RPC_PEER,162.55.132.230:2001,35.236.111.151:26657,34.94.191.28:26657"
              #RPC_SERVERS="osmosis.strange.love:26657,osmosis.strange.love:26657"
              #PERSISTENT_PEERS="2dd86ed01eae5673df4452ce5b0dddb549f46a38@35.236.111.151:26656"
              RPC_SERVERS="$RPC_PEER,$RPC_PEER"
              PERSISTENT_PEERS="2dd86ed01eae5673df4452ce5b0dddb549f46a38@35.236.111.151:26656"
              MINIMUM_GAS_PRICE="0.01uosmo"

              # config.toml
              CONFIG_FILE=$CONFIG_DIR/config.toml
              sed -i '/^enable = false/ s//enable = true/' $CONFIG_FILE # enable state sync
              sed -i "/^trust_height = .*/ s//trust_height = $TRUST_HEIGHT/" $CONFIG_FILE
              sed -i "/^trust_hash = .*/ s//trust_hash = \"$TRUST_HASH\"/" $CONFIG_FILE
              sed -i "/^rpc_servers = .*/ s//rpc_servers = \"$RPC_SERVERS\"/" $CONFIG_FILE
              sed -i '/^indexer = .*/ s//indexer = "null"/' $CONFIG_FILE
              sed -i "/^persistent_peers = .*/ s//persistent_peers = \"$PERSISTENT_PEERS\"/" $CONFIG_FILE
              sed -i "/^external_address = .*/ s//external_address = \"$(curl -s ifconfig.me):26656\"/" $CONFIG_FILE
              sed -i '/^max_num_outbound_peers = .*/ s//max_num_outbound_peers = 80/' $CONFIG_FILE

              # app.toml
              APP_FILE=$CONFIG_DIR/app.toml
              sed -i '/^pruning = .*/ s//pruning = "everything"/' $APP_FILE
              sed -i "/^minimum-gas-prices = .*/ s//minimum-gas-prices = \"$MINIMUM_GAS_PRICE\"/" $APP_FILE
              sed -i "/^snapshot-interval = .*/ s//snapshot-interval = 0/" $APP_FILE


              # First time will error on `Error: error during handshake: error on replay: wrong Block.Header.Version. Expected {11 0}, got {11 1}`
              osmosisd start || true

              # Hack required for osmosis state sync
              tendermint set-app-version 1 --home $CHAIN_DIR
            fi

            # sleep 30

            osmosisd start