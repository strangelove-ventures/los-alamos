            CHAIN_DIR=/home/heighliner/.gaia
            
            if [ ! -d $CHAIN_DIR ]; then
              # Initialize config
              CHAIN_ID=cosmoshub-4
              gaiad config chain-id $CHAIN_ID --home $CHAIN_DIR
              gaiad config keyring-backend test --home $CHAIN_DIR
              gaiad config broadcast-mode block --home $CHAIN_DIR
              gaiad init chain-node --home $CHAIN_DIR --chain-id=$CHAIN_ID

              CONFIG_DIR=$CHAIN_DIR/config

              # Get Genesis JSON
              wget -O - https://github.com/cosmos/mainnet/raw/master/genesis.$CHAIN_ID.json.gz | gunzip -c > $CONFIG_DIR/genesis.json

              RPC_PEER=cosmoshub.strange.love:26657

              STATUS=$(curl -s $RPC_PEER/status)

              LATEST_HEIGHT=$(echo $STATUS | jq -r '.result.sync_info.latest_block_height')
              LATEST_TIME=$(echo $STATUS | jq -r '.result.sync_info.latest_block_time')
              LATEST_TIME_SECONDS=$(date +%s -d "$(echo "${LATEST_TIME::-11}" |  sed 's/T/ /')")
              echo "Latest height: $LATEST_HEIGHT, time seconds: $LATEST_TIME_SECONDS"

              DELTA_BLOCKS=1000

              DELTA_HEIGHT=$(($LATEST_HEIGHT-$DELTA_BLOCKS))
              DELTA_HEIGHT_REQ=$(curl -s $RPC_PEER/block?height=$DELTA_HEIGHT)
              DELTA_HASH=$(echo $DELTA_HEIGHT_REQ | jq -r '.result.block_id.hash')
              DELTA_TIME=$(echo $DELTA_HEIGHT_REQ | jq -r '.result.block.header.time')
              DELTA_TIME_SECONDS=$(date +%s -d "$(echo "${DELTA_TIME::-11}" |  sed 's/T/ /')")
              echo "Delta time seconds: $DELTA_TIME_SECONDS"

              SECONDS_PER_BLOCK=$(awk "BEGIN{printf \"%.02f\", ($LATEST_TIME_SECONDS-$DELTA_TIME_SECONDS)/$DELTA_BLOCKS }")

              echo "Seconds per block: $SECONDS_PER_BLOCK"

              UNBONDING_DAYS=21

              UNBONDING_PERIOD_BLOCKS=$(awk "BEGIN{printf \"%.0f\", $UNBONDING_DAYS * 86400 / $SECONDS_PER_BLOCK }")

              echo "Unbonding period blocks: $UNBONDING_PERIOD_BLOCKS"

              PRUNING_PADDING=1000

              BLOCKS_TO_KEEP=$(awk "BEGIN { print int((($UNBONDING_PERIOD_BLOCKS + $PRUNING_PADDING) / $DELTA_BLOCKS) + 0.5) * $DELTA_BLOCKS }")

              echo "Will retain $BLOCKS_TO_KEEP blocks"

              TRUST_HEIGHT=$DELTA_HEIGHT
              TRUST_HASH=$DELTA_HASH
              echo "Fetching Snapshot Height $TRUST_HEIGHT"
              echo "Using trust height $TRUST_HEIGHT and trust hash $TRUST_HASH"

              RPC_SERVERS="$RPC_PEER,$RPC_PEER"
              PERSISTENT_PEERS="d97f186a3e9579bd70d9e26d0836063382e4462f@34.102.4.160:26656,626caa2a2eba32db9218a6930a93c2b1ea294eae@157.230.31.160:26656,4e8158d78733f214a4fdeed17b17dafa2637db2a@138.197.11.216:26656,a3ce433431b8a82bdc06ee7e24b62f062c189fe3@88.99.105.146:26656,57d105a6d81181336ddb3f85da4b062e2f0152b9@5.189.137.88:26656,bdc2c3d410ca7731411b7e46a252012323fbbf37@10.138.0.14:26656,9526687ee89ab72aa7034e739220bf1744d58709@91.90.43.17:26656,83d6ce5917f624697d308b43c07941e14ed86789@52.16.243.253:26656,cbd79ed2b90092b84c8d0bffb7604b3c7756798a@95.216.1.108:26656,931fa504874c98b41437ad735506929e77a5e38b@46.166.146.165:26656,1d02b4300c6b6fd1123a20502f0b3c0ce3b73654@88.198.16.9:26656,b30c990e45a98415170a24a313c33339495ead4e@159.65.237.30:26656,d9fd3b2029d79c4f5799e5d42e93fcc95e1e0d90@54.241.49.19:26656,89d31aa293ac9c15a8f5063e7010ced65314a052@34.245.145.16:26656,8601bf554d4f34f9501b535196d6f4f670233eac@35.179.15.165:26656,01ed76ede17ac4b8d0f6af52be124c8bd06b5101@168.119.86.15:26656,28d86ce3a32d5d0f64e6cf8dfa1f8c7b10b8ddae@63.250.54.208:26656"
              MINIMUM_GAS_PRICE="0.0025uatom"

              # config.toml
              CONFIG_FILE=$CONFIG_DIR/config.toml
              sed -i '/^enable = false/ s//enable = true/' $CONFIG_FILE # enable state sync
              sed -i "/^trust_height = .*/ s//trust_height = $TRUST_HEIGHT/" $CONFIG_FILE
              sed -i "/^trust_hash = .*/ s//trust_hash = \"$TRUST_HASH\"/" $CONFIG_FILE
              sed -i "/^rpc_servers = .*/ s//rpc_servers = \"$RPC_SERVERS\"/" $CONFIG_FILE
              sed -i '/^indexer = .*/ s//indexer = "kv"/' $CONFIG_FILE
              sed -i "/^persistent_peers = .*/ s//persistent_peers = \"$PERSISTENT_PEERS\"/" $CONFIG_FILE
              sed -i "/^external_address = .*/ s//external_address = \"$(curl -s ifconfig.me):26656\"/" $CONFIG_FILE
              sed -i '/^max_num_inbound_peers = .*/ s//max_num_inbound_peers = 80/' $CONFIG_FILE
              sed -i '/^laddr = "tcp:\/\/127.0.0.1:26657"/ s//laddr = "tcp:\/\/0.0.0.0:26657"/' $CONFIG_FILE
              sed -i '/^cors_allowed_origins = .*/ s//cors_allowed_origins = \["\*"\]/' $CONFIG_FILE
              #sed -i '/^db_backend = .*/ s//db_backend = "rocksdb"/' $CONFIG_FILE

              # app.toml
              APP_FILE=$CONFIG_DIR/app.toml
              sed -i '/^pruning = .*/ s//pruning = "custom"/' $APP_FILE
              sed -i "/^pruning-keep-recent = .*/ s//pruning-keep-recent = \"$BLOCKS_TO_KEEP\"/" $APP_FILE
              sed -i "/^pruning-keep-every = .*/ s//pruning-keep-every = \"0\"/" $APP_FILE
              sed -i "/^pruning-interval = .*/ s//pruning-interval = \"17\"/" $APP_FILE
              sed -i "/^minimum-gas-prices = .*/ s//minimum-gas-prices = \"$MINIMUM_GAS_PRICE\"/" $APP_FILE
              #sed -i '/^enable = false/ s//enable = true/' $APP_FILE # enable api
              #sed -i '/^enabled = false/ s//enabled = true/' $APP_FILE # enable telemetry

              SNAPSHOT_INTERVAL=1000
              SNAPSHOT_KEEP_RECENT=2

              sed -i "/^snapshot-interval = .*/ s//snapshot-interval = $SNAPSHOT_INTERVAL/" $APP_FILE
              sed -i "/^snapshot-keep-recent = .*/ s//snapshot-keep-recent = $SNAPSHOT_KEEP_RECENT/" $APP_FILE
            fi

            # sleep 30

            gaiad start --x-crisis-skip-assert-invariants
