#!/bin/sh

CHAIN_DIR=/home/heighliner/.crescent

if [ ! -d $CHAIN_DIR ]; then
  CONFIG_DIR=$CHAIN_DIR/config
  # Initialize config
  # mainnet
  crescentd init chain-node --chain-id crescent-1

  # testnet
  #crescentd init chain-node --chain-id mooncat-1-1

  # Get Genesis JSON

  # mainnet
  wget -c https://github.com/crescent-network/launch/raw/main/mainnet/genesis.json.tar.gz -O - | tar -xz -C $CONFIG_DIR/

  # testnet
  # wget -c https://github.com/crescent-network/launch/raw/main/testnet/genesis_collect-gentxs.json.tar.gz -O - | tar -xz -C $CONFIG_DIR/

  # mainnet
  SEEDS="929f22a7b04ff438da9edcfebd8089908239de44@18.180.232.184:26656"
  PERSISTENT_PEERS="68787e8412ab97d99af7595c46514b9ab4b3df45@54.250.202.17:26656,0ed5ed53ec3542202d02d0d47ac04a2823188fc2@52.194.172.170:26656,04016e800a079c8ee5bdb9361c81c026b6177856@34.146.27.138:26656,24be64cd648958d9f685f95516cb3b248537c386@52.197.140.210:26656,83b3ba06b43fda52c048934498c6ee2bd4987d2d@3.39.144.72:26656,7e59c83196fdc61dcf9d36c42776c0616bc0fc8c@3.115.85.120:26656,06415494b86316c55245d162da065c3c0fee83fc@172.104.108.21:26656,4293ce6b47ee2603236437ab44dc499519c71e62@45.76.97.48:26656,4113f7496857d3f161921c7af8d62022551a7e6b@167.179.75.240:26656,2271e3739ea477bce0df39dd9e95f8b952a2106e@198.13.62.7:26656,b34115ba926eb12059ca0ade4d1013cac2f8d289@crescent-mainnet-01.01node.com:26656,d7556e41ba2f333379f6d87b1af3cce2ca545f79@34.88.102.246:26656,26011ac36240fb49852cc7196f71a1884434b8c4@34.84.227.139:26656,b840926fb6a2bd04fc70e501002f9286655c9179@52.199.91.143:30732,86030850dd635cab1f136979568087407a025491@46.101.153.158:26656"

  # testnet
  # SEEDS="1fe40daaf2643fd3857e30f86ff30ea82bf1c03b@54.169.204.99:26656"
  # PERSISTENT_PEERS="2d8e31ad11b840c5ce7f1900b4da3a3bcf0985ef@139.59.151.125:26656,09e76cfbe89357d6bb3b16c4d013f420721b6664@50.18.111.23:26656,3802abfdf8a1c0a60041e684b08b6bec92d0a325@178.62.19.161:26656,2821cee54928a0fe1db97376ae7c48c4f0a9528a@137.184.127.205:26656,b2d2685e01641264fff25f5b3be23eacbdf9b08d@3.35.211.36:26656,29b006edeb2e0ee9bbe05060ebc6550549dc656e@218.53.140.56:20406,e2f735b5ecb6f909d09f4e3ebce6a90c63d18fbe@59.13.223.197:30535,b91b8ab43d8fc161587f09a09ccbb7fda7c41beb@37.120.245.39:26656,841f1cfa0174017813e2291cfa845001391a2cee@crescent-testnet.01no.de:26656,bdce75b9a471de6d131571b0c40ce6070d7da878@80.64.208.109:26656"


  MINIMUM_GAS_PRICE="0.01ucre,0.01ubcre"

  # config.toml
  CONFIG_FILE=$CONFIG_DIR/config.toml
  sed -i '/^indexer = .*/ s//indexer = "null"/' $CONFIG_DIR/config.toml
  sed -i "/^persistent_peers = .*/ s//persistent_peers = \"$PERSISTENT_PEERS\"/" $CONFIG_FILE
  sed -i "/^external_address = .*/ s//external_address = \"$(curl -s ifconfig.me):26656\"/" $CONFIG_FILE
  sed -i "/^seeds = .*/ s//seeds = \"$SEEDS\"/" $CONFIG_FILE

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

crescentd start
