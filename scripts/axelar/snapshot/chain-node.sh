              #!/bin/sh

              CHAIN_DIR=/home/heighliner/.axelar

              if [ ! -d $CHAIN_DIR ]; then

                # Mainnet
                # CHAIN_ID=axelar-dojo-1
                
                # Testnet
                CHAIN_ID=axelar-testnet-lisbon-3

                # Initialize config
                axelard init chain-node

                CONFIG_DIR=$CHAIN_DIR/config

                AXELAR_NET="https://raw.githubusercontent.com/axelarnetwork/axelarate-community/main/resources"

                # Address book
                # Mainnet
                # wget -O $CONFIG_DIR/addrbook.axelar.json https://quicksync.io/addrbook.axelar.json
                # Testnet
                wget -O $CONFIG_DIR/addrbook.axelartestnet.json https://quicksync.io/addrbook.axelartestnet.json


                # Get Genesis JSON
                # Mainnet
                # wget -O $CONFIG_DIR/genesis.json $AXELAR_NET/mainnet/genesis.json
                # Testnet
                wget -O $CONFIG_DIR/genesis.json $AXELAR_NET/testnet/genesis.json

                # Get seeds
                # Mainnet
                # SEEDS=$(curl -s "$AXELAR_NET/mainnet/seeds.txt" | paste -d, -s)
                # Testnet
                SEEDS=$(curl -s "$AXELAR_NET/testnet/seeds.txt" | paste -d, -s)

                MINIMUM_GAS_PRICE="0.00005uaxl"

                # config.toml
                CONFIG_FILE=$CONFIG_DIR/config.toml
                sed -i '/^indexer = .*/ s//indexer = "kv"/' $CONFIG_FILE
                sed -i "/^external_address = .*/ s//external_address = \"$(curl -s ifconfig.me):26656\"/" $CONFIG_FILE
                sed -i '/^laddr = "tcp:\/\/127.0.0.1:26657"/ s//laddr = "tcp:\/\/0.0.0.0:26657"/' $CONFIG_FILE
                sed -i '/^max_num_outbound_peers = .*/ s//max_num_outbound_peers = 20/' $CONFIG_FILE
                sed -i '/^max_num_inbound_peers = .*/ s//max_num_inbound_peers = 20/' $CONFIG_FILE
                sed -i "/^seeds = .*/ s//seeds = \"$SEEDS\"/" $CONFIG_FILE
                sed -i '/^cors_allowed_origins = .*/ s//cors_allowed_origins = \["\*"\]/' $CONFIG_FILE

                # app.toml
                APP_FILE=$CONFIG_DIR/app.toml
                sed -i '/^pruning = .*/ s//pruning = "nothing"/' $APP_FILE
                # sed -i '/^pruning-keep-recent = .*/ s//pruning-keep-recent = "100000"/' $APP_FILE
                # sed -i '/^pruning-keep-every = .*/ s//pruning-keep-every = "0"/' $APP_FILE
                # sed -i '/^pruning-interval = .*/ s//pruning-interval = "17"/' $APP_FILE
                sed -i "/^minimum-gas-prices = .*/ s//minimum-gas-prices = \"$MINIMUM_GAS_PRICE\"/" $APP_FILE
                sed -i "/^snapshot-interval = .*/ s//snapshot-interval = 1000/" $APP_FILE

                # Mainnet
                # URL=`curl https://quicksync.io/axelar.json|jq -r '.[] |select(.file=="axelar-dojo-1-default")|.url'`

                 # Testnet
                URL=`curl https://quicksync.io/axelar.json|jq -r '.[] |select(.file=="axelartestnet-lisbon-3-pruned")|.url'`

                wget -O - $URL | lz4 -d | tar -xv -C $CHAIN_DIR
              fi

              # sleep 30

              axelard start