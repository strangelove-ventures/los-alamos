#!/bin/bash

POD_PREFIX=$1
PV_SIZE=$2
HEIGHLINER_IMAGE_TAG=$3
SCRIPT=$4

generate_node_kubernetes_config_yaml () {
  NAME=$1
  N=$2
  NODE_NAME=$3
  VOLUME_SIZE=$4
  HEIGHLINER_IMAGE=$5
  SCRIPT_PATH=$6

  NODE_FILE=${NAME}-${N}.yaml
  SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
  cp "$SCRIPT_DIR/node_template.yaml" $NODE_FILE

  sed "s/\${NAME}/$NAME/g" -i $NODE_FILE
  sed "s/\${N}/$N/g" -i $NODE_FILE
  sed "s/\${NODE_NAME}/$NODE_NAME/g" -i $NODE_FILE
  sed "s/\${VOLUME_SIZE}/$VOLUME_SIZE/g" -i $NODE_FILE
  sed "s/\${HEIGHLINER_IMAGE}/$HEIGHLINER_IMAGE/g" -i $NODE_FILE
  # SCRIPT_CONTENTS=`cat $SCRIPT_PATH | tr '\n' "\\n"`
  # DATA="$(cat $SCRIPT_PATH)"
  # ESCAPED_DATA="$(echo "${DATA}" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\$/\\$/g')"
  # echo $ESCAPED_DATA
  # sed 's/\${SCRIPT}/'"${ESCAPED_DATA}"'/' -i $NODE_FILE
  sed -i -e "/\${SCRIPT}/r $SCRIPT_PATH" -e "//d" $NODE_FILE


  #kubectl apply -f $NODE_FILE
}

KUBE_NODES=($(kubectl get nodes -o name | cut -c 6-))

for i in "${!KUBE_NODES[@]}"; do
  N=$(($i + 1))

  generate_node_kubernetes_config_yaml $POD_PREFIX $N "${KUBE_NODES[$i]}" $PV_SIZE $HEIGHLINER_IMAGE_TAG $SCRIPT
done
