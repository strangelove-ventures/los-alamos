## Tools to help with administering GKE clusters

### Shell functions

These can be added to your shell's interactive startup script, e.g. ~/.bashrc or ~/.zshrc for bash or zsh, respectively.

#### GKE cluster authentication (kubeconfig)
```bash
function gke() {
  gcloud config set project $1
  CLUSTER_ROW=$(gcloud container clusters list | grep $2)
  CLUSTER_NAME=$(echo $CLUSTER_ROW | awk '{ print $1 }')
  REGION=$(echo $CLUSTER_ROW | awk '{ print $2 }')
  echo "Connecting to cluster $CLUSTER_NAME in region $REGION"
  gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION
}
```

- Usage: `gke $PROJECT_ID $CLUSTER_NAME_QUERY`
- Example: `gke infrastructure osmosis` to generate kubeconfig for a GKE cluster in the gcloud project with `project-id: infrastructure` that contains the text `osmosis` in the cluster name. Now, `kubectl` commands will interact with the desired cluster (e.g. `kubectl get nodes`, `kubectl get pods`, `kubectl logs --tail=20 $POD_NAME`).

#### Start VPN tunnel to private GKE Horcrux cluster

```bash
function gke_jump() {
  gke $1 horcrux
  JUMPBOX_EXTERNAL_IP=$(gcloud compute instances list | grep jumpbox | awk '{ print $5}')
  sshuttle -r $USER@$JUMPBOX_EXTERNAL_IP 0.0.0.0/0 -vv
}
```

- Usage: `gke_jump $PROJECT_ID`
- Example: `gke sl-osmosis-val` to authenticate to private horcrux GKE cluster in the gcloud project with `project-id: sl-osmosis-val` and start the VPN tunnel using sshuttle. Now, `kubectl` commands will interact with the private cluster. Kill the separate terminal running `gke_jump` once finished with cluster maintenance.

### Shell Scripts

Alternatively, you can use [gke.sh](../scripts/gke.sh) for GKE cluster management if you do not want to modify your rc/profile files.

Add script (or symlink to this script) to a directory in your `$PATH` for easier access.
