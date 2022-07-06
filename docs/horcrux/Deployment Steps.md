# Deploy Horcrux Validator to Google Cloud

Uses terraform to deploy two Google Kubernetes Engine (GKE) clusters, one private cluster for the horcrux signers, and one public cluster for the sentry nodes that will handle state sync and p2p with the blockchain.

### Enable Google Cloud APIs

- Compute Engine API
- Kubernetes Engine API

### Request Google Cloud Quota Increases

- CPUS_ALL_REGIONS - 50
- N2D_CPUS for specific region - 50
- IN_USE_ADDRESSES for specific region - 20
- SSD_TOTAL_GB for specific region - (20GB * number horcrux nodes) and (100GB + node db size) per sentry


### Create infrastructure

Create a new folder for your specific validator deployment. Populate `main.tf` using the terraform `horcrux` module in this project. All possible variables can be found [here](../../terraform/horcrux/variables.tf)

```terraform
module "gke_horcrux_validator_network" {
  source = "github.com/strangelove-ventures/los-alamos//terraform/horcrux"

  #vars
}
```

An example `main.tf` terraform deployment file to deploy a cosmoshub horcrux validator is provided in [examples/horcrux/cosmoshub/main.tf](../../examples/horcrux/cosmoshub/main.tf)

#### Deploy infrastructure

```bash
terraform init
terraform apply
```

#### Environment vars

Populate environment variables used for the rest of this deployment.
```bash
CLUSTER_NAME=hub
CHAIN_ID=cosmoshub-4
HORCRUX_VERSION=v2.0.0-beta3
THRESHOLD=2
SENTRY_VERSION=gaia:v6.0.3 # choose from https://github.com/orgs/strangelove-ventures/packages?tab=packages&q=heighliner
SENTRY_SSD_SIZE=500Gi # modify as needed for chain
REGION=us-central1
```

### Setup sentry cluster
```bash
gcloud container clusters get-credentials $CLUSTER_NAME-sentry --region $REGION
../../../scripts/node/k8s_node.sh $CLUSTER_NAME-sentry $SENTRY_SSD_SIZE $SENTRY_VERSION ../../../scripts/cosmoshub/statesync/sentry.sh
kubectl apply -f $CLUSTER_NAME-sentry-1.yaml
kubectl apply -f $CLUSTER_NAME-sentry-2.yaml
kubectl apply -f $CLUSTER_NAME-sentry-3.yaml
# ...

# Wait for sentries to be in sync
kubectl logs sentry-0 # or sentry-1 sentry-2
```

### In separate terminal, connect VPN through jumpbox
```bash
JUMPBOX_NAME=gke-$CLUSTER_NAME-jumpbox
JUMPBOX_EXTERNAL_IP=$(gcloud compute instances list | grep $JUMPBOX_NAME | awk '{ print $5}')

# SSH into jumpbox to generate SSH keys
gcloud compute ssh $JUMPBOX_NAME
exit

# VPN tunnel from local machine through jumpbox using sshuttle
sshuttle -r $USER@$JUMPBOX_EXTERNAL_IP 0.0.0.0/0 -vv
```

### Shard private key
#### Place priv_validator_key.json in this directory
#### If key is already sharded, skip this step and instead copy in private_share_*.json files
```bash
horcrux create-shares priv_validator_key.json $THRESHOLD 3
```

### Get kubeconfig for horcrux GKE cluster
```bash
gcloud container clusters get-credentials $CLUSTER_NAME-horcrux --region $REGION
```

### Create gcloud secrets
```bash
kubectl create secret generic private-share-1 --from-file private_share_1.json
kubectl create secret generic private-share-2 --from-file private_share_2.json
kubectl create secret generic private-share-3 --from-file private_share_3.json
# ...
```

### Generate kubernetes configuration and apply to cluster
```bash
../../../scripts/horcrux/k8s_horcrux.sh $THRESHOLD $HORCRUX_VERSION $CHAIN_ID
# Apply each signer file
kubectl apply -f horcrux_signer_1.yaml
kubectl apply -f horcrux_signer_2.yaml
kubectl apply -f horcrux_signer_3.yaml
# ...
```

### Enable privval listener on all sentries
```bash
gcloud container clusters get-credentials $CLUSTER_NAME-sentry --region $REGION

# Config file inside container. Change for relative chain. User is root inside of heighliner docker images
CONFIG_FILE=/home/heighliner/.gaia/config/config.toml

PODS=($(kubectl get pods --no-headers | awk '{ print $1 }'))

for POD in "${PODS[@]}"; do
  kubectl exec -it $POD -- sed -i '/^priv_validator_laddr = .*/ s//priv_validator_laddr = "tcp:\/\/0.0.0.0:1234"/' $CONFIG_FILE
  kubectl delete --wait=false pod $POD
done
```

### You are done!

#### To destroy everything
```bash
terraform destroy
```
