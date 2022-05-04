            #!/bin/sh

            CHAIN_DIR=/home/heighliner/.osmosisd

            if [ ! -d $CHAIN_DIR ]; then
              # Initialize config
              osmosisd init chain-node

              CONFIG_DIR=$CHAIN_DIR/config

              # Get Genesis JSON
              wget -O $CONFIG_DIR/genesis.json https://github.com/osmosis-labs/networks/raw/main/osmosis-1/genesis.json

              PERSISTENT_PEERS="d2343b88b4487740cf4ea09e6cb4631a9d90171b@35.225.241.195:26656,2dd86ed01eae5673df4452ce5b0dddb549f46a38@35.236.111.151:26656"
              MINIMUM_GAS_PRICE="0.01uosmo"

              # config.toml
              CONFIG_FILE=$CONFIG_DIR/config.toml
              sed -i '/^indexer = .*/ s//indexer = "null"/' $CONFIG_FILE
              sed -i "/^persistent_peers = .*/ s//persistent_peers = \"$PERSISTENT_PEERS\"/" $CONFIG_FILE
              sed -i "/^external_address = .*/ s//external_address = \"$(curl -s ifconfig.me):26656\"/" $CONFIG_FILE
              sed -i '/^max_num_outbound_peers = .*/ s//max_num_outbound_peers = 80/' $CONFIG_FILE

              # app.toml
              APP_FILE=$CONFIG_DIR/app.toml
              sed -i '/^pruning = .*/ s//pruning = "custom"/' $APP_FILE
              sed -i '/^pruning-keep-recent = .*/ s//pruning-keep-recent = "100"/' $APP_FILE
              sed -i '/^pruning-keep-every = .*/ s//pruning-keep-every = "0"/' $APP_FILE
              sed -i '/^pruning-interval = .*/ s//pruning-interval = "10"/' $APP_FILE
              sed -i "/^minimum-gas-prices = .*/ s//minimum-gas-prices = \"$MINIMUM_GAS_PRICE\"/" $APP_FILE
              sed -i "/^snapshot-interval = .*/ s//snapshot-interval = 0/" $APP_FILE

              wget -O osmosis_3143626.tar.lz4 https://tendermint-snapshots.polkachu.xyz/osmosis/osmosis_3143626.tar.lz4
              lz4 -c -d osmosis_3143626.tar.lz4  | tar -x -C $CHAIN_DIR
              rm -rf osmosis_3143626.tar.lz4
            fi

            # sleep 30

            osmosisd start