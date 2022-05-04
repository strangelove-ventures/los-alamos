              #!/bin/sh

              CHAIN_DIR=/home/heighliner/.akash

              if [ ! -d $CHAIN_DIR ]; then
                # Initialize config
                AKASH_NET="https://raw.githubusercontent.com/ovrclk/net/master/mainnet"

                export AKASH_CHAIN_ID="$(curl -s "$AKASH_NET/chain-id.txt")"
                akash init --chain-id "$AKASH_CHAIN_ID" sentry

                CONFIG_DIR=$CHAIN_DIR/config

                # Get Genesis JSON
                curl -s "$AKASH_NET/genesis.json" > $CONFIG_DIR/genesis.json

                PERSISTENT_PEERS=$(curl -s "$AKASH_NET/peer-nodes.txt" | paste -d, -s)
                SEEDS=$(curl -s "$AKASH_NET/seed-nodes.txt" | paste -d, -s)
                MINIMUM_GAS_PRICE="0.025uakt"

                # config.toml
                CONFIG_FILE=$CONFIG_DIR/config.toml
                sed -i '/^indexer = .*/ s//indexer = "null"/' $CONFIG_FILE
                sed -i "/^persistent_peers = .*/ s//persistent_peers = \"$PERSISTENT_PEERS\"/" $CONFIG_FILE
                sed -i "/^seeds = .*/ s//seeds = \"$SEEDS\"/" $CONFIG_FILE
                sed -i "/^external_address = .*/ s//external_address = \"$(curl -s ifconfig.me):26656\"/" $CONFIG_FILE
                #sed -i '/^max_num_inbound_peers = .*/ s//max_num_inbound_peers = 80/' $CONFIG_FILE
                #sed -i '/^max_num_outbound_peers = .*/ s//max_num_outbound_peers = 80/' $CONFIG_FILE

                # app.toml
                APP_FILE=$CONFIG_DIR/app.toml
                sed -i '/^pruning = .*/ s//pruning = "custom"/' $APP_FILE
                sed -i '/^pruning-keep-recent = .*/ s//pruning-keep-recent = "100"/' $APP_FILE
                sed -i '/^pruning-keep-every = .*/ s//pruning-keep-every = "0"/' $APP_FILE
                sed -i '/^pruning-interval = .*/ s//pruning-interval = "10"/' $APP_FILE
                sed -i "/^minimum-gas-prices = .*/ s//minimum-gas-prices = \"$MINIMUM_GAS_PRICE\"/" $APP_FILE
                sed -i "/^snapshot-interval = .*/ s//snapshot-interval = 0/" $APP_FILE

                wget -O akash_4678707.tar.lz4 https://tendermint-snapshots.polkachu.xyz/akash/akash_4678707.tar.lz4
                lz4 -c -d akash_4678707.tar.lz4  | tar -x -C $CHAIN_DIR
                rm -rf akash_4678707.tar.lz4

              fi

              # sleep 30

              akash start