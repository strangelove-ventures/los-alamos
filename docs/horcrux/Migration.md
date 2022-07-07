## Migration from one Horcrux GKE Project to another (minimal downtime):

Prepare 2 terminals, one for commands and the other for the sshuttle connection to the private subnets.

### In first terminal, start with working directory in horcrux, set vars, and duplicate project
```bash
cd horcrux

OLD_DIR=vega_testnet # Directory of terraform/kube files for OLD project
NEW_DIR=vega_testnet_new  # Directory of terraform/kube files for NEW project
OLD_PROJECT=strangelove-infrastructure # Gcloud project-id of OLD project
NEW_PROJECT=horcrux-validator-gke-test # Gcloud project-id of NEW project

# Recommend different cluster names in case of not following instructions perfectly
OLD_CLUSTER_NAME=vega-testnet
NEW_CLUSTER_NAME=vega-test
CHAIN_ID=vega-testnet # assumes same chain as old cluster
HORCRUX_VERSION=v2.0.0-beta3 # horcrux version for new cluster
THRESHOLD=2 # threshold used when sharding private key

cp -R $OLD_DIR $NEW_DIR
cd $NEW_DIR
rm -rf .terraform .terraform.lock.hcl horcrux_signer_*.yaml terraform.tfstate
```

### Modify at least project_id and cluster_name in $NEW_DIR/terraform.tfvars to match above vars

### In second terminal, set cluster name vars same as first terminal

```bash
OLD_CLUSTER_NAME=vega-testnet
NEW_CLUSTER_NAME=vega-test
```

### In first terminal, Set vars and spin up infra in new project
```bash
gcloud config set project $NEW_PROJECT

# Spin up new infrastructure
terraform init
terraform apply
```

### In second terminal, get jumpbox NAME and EXTERNAL_IP for new project
```bash
NEW_JUMPBOX_NAME=gke-$NEW_CLUSTER_NAME-jumpbox
NEW_JUMPBOX_EXTERNAL_IP=$(gcloud compute instances list | grep gke-$NEW_CLUSTER_NAME-jumpbox | awk '{ print $5}')

# SSH into jumpbox to generate SSH keys if necessary (will be used in later step)
gcloud compute ssh $NEW_JUMPBOX_NAME
exit
```

### In first terminal, startup sentries in new project without privval connection and wait for them to be in sync
```bash
gcloud container clusters get-credentials $NEW_CLUSTER_NAME-sentry --region us-central1
kubectl apply -f sentry.yaml
```

#### In first terminal, wait for sentries to be in sync by checking with command
```bash
kubectl logs sentry-0
```

#### In first terminal, switch to old project

```bash
cd ..
cd $OLD_DIR

gcloud config set project $OLD_PROJECT
```

### In second terminal, populate OLD_JUMPBOX vars and connect

```bash
OLD_JUMPBOX_NAME=gke-$OLD_CLUSTER_NAME-jumpbox
OLD_JUMPBOX_EXTERNAL_IP=$(gcloud compute instances list | grep gke-$OLD_CLUSTER_NAME-jumpbox | awk '{ print $5}')
sudo echo # cache sudo password so that starting sshuttle is faster for moments of truth below
sshuttle -r $USER@$OLD_JUMPBOX_EXTERNAL_IP 0.0.0.0/0 -vv
```

## MOMENTS OF TRUTH

### In first terminal, get old horcrux GKE kubeconfig, and delete cluster. will stop signing from the old project.
```bash
# Kube auth for old horcrux cluster
gcloud container clusters get-credentials $OLD_CLUSTER_NAME-horcrux --region us-central1

# Delete all horcrux_signer_*.yaml
kubectl delete -f horcrux_signer_1.yaml
kubectl delete -f horcrux_signer_2.yaml
kubectl delete -f horcrux_signer_3.yaml

# Make sure all signer pods are gone
kubectl get pods

# Kube auth for old sentry cluster
gcloud container clusters get-credentials $OLD_CLUSTER_NAME-sentry --region us-central1
kubectl delete -f sentry.yaml
```

### In first terminal, switch to new project
```bash
cd ..
cd $NEW_DIR

gcloud config set project $NEW_PROJECT
```

### In second terminal, kill (Ctrl+C) the sshuttle connection to the OLD jumpbox, and connect to NEW jumpbox

```bash
# (Ctrl + C) first, then:
sshuttle -r $USER@$NEW_JUMPBOX_EXTERNAL_IP 0.0.0.0/0 -vv
```

### In first terminal, setup horcrux signer cluster, then enable privval on sentry cluster

```bash
# Kube auth for new horcrux cluster
gcloud container clusters get-credentials $NEW_CLUSTER_NAME-horcrux --region us-central1

# Create gcloud secrets
kubectl create secret generic private-share-1 --from-file private_share_1.json
kubectl create secret generic private-share-2 --from-file private_share_2.json
kubectl create secret generic private-share-3 --from-file private_share_3.json

# Generate kubernetes configuration and apply to cluster
../k8s_horcrux.sh $THRESHOLD $HORCRUX_VERSION $CHAIN_ID

# Kube auth for new sentry cluster
gcloud container clusters get-credentials $NEW_CLUSTER_NAME-sentry --region us-central1

# Enable privval listener on all sentries
kubectl exec -it sentry-0 -- sed -i '/^priv_validator_laddr = .*/ s//priv_validator_laddr = "tcp:\/\/0.0.0.0:1234"/' /home/heighliner/.gaia/config/config.toml
kubectl exec -it sentry-1 -- sed -i '/^priv_validator_laddr = .*/ s//priv_validator_laddr = "tcp:\/\/0.0.0.0:1234"/' /home/heighliner/.gaia/config/config.toml
kubectl exec -it sentry-2 -- sed -i '/^priv_validator_laddr = .*/ s//priv_validator_laddr = "tcp:\/\/0.0.0.0:1234"/' /home/heighliner/.gaia/config/config.toml

# Restart sentry pods
kubectl delete pod sentry-0 sentry-1 sentry-2
```

### Wait for the new cluster to pick up signing blocks

### Tear down old cluster

#### In first terminal, switch to old project

```bash
cd ..
cd $OLD_DIR

gcloud config set project $OLD_PROJECT
terraform destroy
```

Woohoo! you are done!
