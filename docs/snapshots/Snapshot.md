# GKE Spanshots using Container Storage Interface
In Google Kubernetes Engine (GKE), you can use the Kubernetes volume snapshot feature for persistent volumes in your GKE clusters.

Volume snapshots let you create a copy of your volume at a specific point in time. You can use this copy to bring a volume back to a prior state or to provision a new volume.  The example below will show you how to both create and restore a snapshot inside GKE using juno-6 as an example.



## Create Snapshot

### Backup the juno-6 ReplicationController  
```
kubectl get rc juno-6 -o yaml > juno-6.yaml
```

### Delete the replication controller for juno-6  
```
kubectl delete rc juno-6
```

### Create VolumeSnapshotClass
```
cat <<EOF | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: pd.csi.storage.gke-snapclass
parameters:
  # storage-locations: us-east4
  type: pd-ssd
driver: pd.csi.storage.gke.io
deletionPolicy: Delete
EOF
```

### Create VolumeSnapshot
```
cat <<EOF | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: juno6-snap
spec:
  volumeSnapshotClassName: pd.csi.storage.gke-snapclass
  source:
    persistentVolumeClaimName: pvc-juno-6
EOF
```

wait for snapshot to finish and confirm you see it in google cloud.

### Restart Replication Controller
```
kubectl apply -f juno-6.yaml
```

## Restore from Snapshot

### Backup the juno-6 ReplicationController  
```
kubectl get rc juno-6 -o yaml > juno-6.yaml
```

### Delete the replication controller for juno-6  
```
kubectl delete rc juno-6
```

### Delete juno6 pvc
```
kubectl delete pvc pvc-juno-6
```

### Create PVC from snap claim
```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-juno-6-restore
spec:
  dataSource:
    name: juno6-snap
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  storageClassName: premium-rwo
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 400Gi
EOF
```

### Recreate Replication Controller with new PVC claim

```
yq '.spec.template.spec.volumes[0].persistentVolumeClaim.claimName = "restore-pvc-juno-6"' juno-6.yaml
```

### Restart Replication Controller
```
kubectl apply -f juno-6.yaml
```