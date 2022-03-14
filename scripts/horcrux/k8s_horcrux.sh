#!/bin/bash

# Need to be authenticated with gcloud, have gcloud project set,
# and have horcrux gke cluster kubeconfig before running this.

THRESHOLD=${1:-2}
HORCRUX_VERSION=${2:-v2.0.0-beta3}
CHAIN_ID=${3:-vega-testnet}

generate_signer_kubernetes_config_yaml () {
  N=$1
  T=$2
  NODE_NAME=$3
  SENTRY_URL=$4
  PEERS_STRING=$5

  SIGNER_FILE=horcrux_signer_$N.yaml
  SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
  cp "$SCRIPT_DIR/horcrux_template.yaml" $SIGNER_FILE

  sed "s/\${N}/$N/g" -i $SIGNER_FILE
  sed "s/\${T}/$T/g" -i $SIGNER_FILE
  sed "s/\${NODE_NAME}/$NODE_NAME/g" -i $SIGNER_FILE
  sed "s/\${HORCRUX_VERSION}/$HORCRUX_VERSION/g" -i $SIGNER_FILE
  sed "s/\${SENTRY_URL}/$SENTRY_URL/g" -i $SIGNER_FILE
  sed "s/\${PEERS_STRING}/$PEERS_STRING/g" -i $SIGNER_FILE
  sed "s/\${CHAIN_ID}/$CHAIN_ID/g" -i $SIGNER_FILE

  #kubectl apply -f $SIGNER_FILE
}

HORCRUX_NODES=($(kubectl get nodes -o name | cut -c 6-))
SENTRY_IPS=($(gcloud compute instances list | grep sentry | awk '{ print $4 }'))

for i in "${!SENTRY_IPS[@]}"; do
  if (( $i == 0 )); then
    SENTRY_ADDRESSES="tcp:\/\/${SENTRY_IPS[$i]}:31234"
  else
    SENTRY_ADDRESSES="$SENTRY_ADDRESSES,tcp:\/\/${SENTRY_IPS[$i]}:31234"
  fi
done

for i in "${!HORCRUX_NODES[@]}"; do
  N=$(($i + 1))

  PEERS_STRING=""
  for j in "${!HORCRUX_NODES[@]}"; do
    SUB_N=$(($j + 1))
    if [[ "$N" != "$SUB_N" ]]; then
      if [[ "$PEERS_STRING" = "" ]]; then
        PEERS_STRING="tcp:\/\/signer-$SUB_N:2222|$SUB_N"
      else
        PEERS_STRING="$PEERS_STRING,tcp:\/\/signer-$SUB_N:2222|$SUB_N"
      fi
    fi
  done

  generate_signer_kubernetes_config_yaml $N $THRESHOLD "${HORCRUX_NODES[$i]}" "$SENTRY_ADDRESSES" $PEERS_STRING
done
