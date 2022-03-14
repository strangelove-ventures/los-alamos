            CHAIN_DIR=/root/.gaia

            if [ ! -d $CHAIN_DIR ]; then
              # Initialize config
              gaiad config chain-id vega-testnet --home $CHAIN_DIR
              gaiad config keyring-backend test --home $CHAIN_DIR
              gaiad config broadcast-mode block --home $CHAIN_DIR
              gaiad init sentry --home $CHAIN_DIR --chain-id=vega-testnet

              CONFIG_DIR=$CHAIN_DIR/config

              # Get Genesis JSON
              wget -O - https://github.com/cosmos/vega-test/raw/master/public-testnet/modified_genesis_public_testnet/genesis.json.gz | gunzip -c > $CONFIG_DIR/genesis.json

              # Get trusted hash and height
              # TODO replace all this with lens
              apk add jq curl # Should be in heighliner Dockerfile if this was permanent, but we are going to remove this for lens
              STATUS=$(curl http://198.50.215.1:46657/status)
              LATEST_HEIGHT=$(echo $STATUS | jq -r '.result.sync_info.latest_block_height')
              echo "Latest height: $LATEST_HEIGHT"
              TRUST_HEIGHT=$(($LATEST_HEIGHT-1000))
              echo "Fetching Snapshot Height $TRUST_HEIGHT"
              TRUST_HEIGHT_REQ=$(curl http://198.50.215.1:4317/blocks/$TRUST_HEIGHT)
              TRUST_HASH=$(echo $TRUST_HEIGHT_REQ | jq -r '.block_id.hash')

              echo "Using trust height $TRUST_HEIGHT and trust hash $TRUST_HASH"

              # config.toml
              CONFIG_FILE=$CONFIG_DIR/config.toml
              sed -i '/^enable = false/ s//enable = true/' $CONFIG_FILE
              sed -i '/^indexer = .*/ s//indexer = "null"/' $CONFIG_FILE
              sed -i "/^trust_height = .*/ s//trust_height = $TRUST_HEIGHT/" $CONFIG_FILE
              sed -i "/^trust_hash = .*/ s//trust_hash = \"$TRUST_HASH\"/" $CONFIG_FILE
              sed -i '/^rpc_servers = .*/ s//rpc_servers = "198.50.215.1:46657,198.50.215.1:36657,143.244.151.9:26657"/' $CONFIG_FILE
              sed -i '/^persistent_peers = .*/ s//persistent_peers = "99b04a4efd48846f654da25532c85bd1fa6a6a39@198.50.215.1:46656,1edc806e29bfb380dc0298ce4fded8e3e8554e2a@198.50.215.1:36656,66a9e52e207c8257b791ff714d29100813e2fa00@143.244.151.9:26656,5303f0b47c98727cd7b19965c73b39ce115d3958@134.122.35.247:26656,9e1e3ce30f22083f04ea157e287d338cf20482cf@165.22.235.50:26656,b7feb9619bef083e3a3e86925824f023c252745b@143.198.41.219:26656"/' $CONFIG_FILE
              sed -i "/^external_address = .*/ s//external_address = \"$(curl --silent ifconfig.me):26656\"/" $CONFIG_FILE
              sed -i "/^max_num_inbound_peers = .*/ s//max_num_inbound_peers = 80/" $CONFIG_FILE

              # app.toml
              APP_FILE=$CONFIG_DIR/app.toml
              sed -i '/^minimum-gas-prices = .*/ s//minimum-gas-prices = "0.001uatom"/' $APP_FILE
              sed -i '/^pruning = .*/ s//pruning = "everything"/' $APP_FILE
            fi

            # Start gaiad
            gaiad start --x-crisis-skip-assert-invariants
