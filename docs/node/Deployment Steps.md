# Deploy Chain Node cluster to Google Cloud

Uses terraform to deploy a Google Kubernetes Engine (GKE) cluster for chain nodes, e.g. genesis archives, relayer node clusters, etc.

### Request Google Cloud Quota Increases

- CPUS_ALL_REGIONS - 50
- IN_USE_ADDRESSES for specific region - 20
- SSD PERSISTENT DISK SSD GB for specific region - ((100GB + node db size) * number of nodes)

### Create infrastructure

#### Populate infrastructure parameters

Create a new folder in your infrastructure repository for your specific node cluster deployment. Populate `main.tf` using the terraform `node` module in this project. All possible variables can be found [here](../../terraform/node/variables.tf)

```hcl
module "gke_chain_node_network" {
  source = "github.com/strangelove-ventures/infra-modules//terraform/node"

  # vars
}
```

An example `main.tf` terraform deployment file to deploy a cosmoshub node cluster is provided in [examples/node/cosmoshub/main.tf](../../examples/node/cosmoshub/main.tf)

#### Deploy infrastructure

```bash
terraform init
terraform apply
```

### Setup kubernetes deployment

```bash
# Variables for this deployment
CLUSTER_NAME=cosmoshub
HEIGHLINER_IMAGE=gaia:v6.0.3 # choose from https://github.com/orgs/strangelove-ventures/packages?tab=packages&q=heighliner
SENTRY_SCRIPT=../../../scripts/cosmoshub/statesync/chain-node.sh
SENTRY_SSD_SIZE=800Gi # change as needed for expected chain db size

gcloud container clusters get-credentials $CLUSTER_NAME --region us-central1 # authenticate to GKE cluster
../../../scripts/node/k8s_node.sh $CLUSTER_NAME $SENTRY_SSD_SIZE $HEIGHLINER_IMAGE $SENTRY_SCRIPT # generate kube files

# Apply all generated kube files
kubectl apply -f $CLUSTER_NAME-1.yaml
kubectl apply -f $CLUSTER_NAME-2.yaml
kubectl apply -f $CLUSTER_NAME-3.yaml
```

### You are done!

#### Basic Kubernetes Administration

```bash
kubectl get pods

# Get logs
kubectl logs $POD_NAME

# Shell into container
kubectl exec -it $POD_NAME -- sh

# Delete kube deployment for node
kubectl delete -f $CLUSTER_NAME-1.yaml
```

#### To destroy everything
```bash
terraform destroy
```
