#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Usage:
  gke.sh [subcommand] [flags]

  Authenticate and connect to GKE clusters

Subcommands:
  auth                 Authenticate to a cluster with public control plane (updates kubeconfig)
  jump                 Start VPN tunnel to private GKE Horcrux cluster

Flags:
  --help              print this help message
  --project           [required] Google Cloud project id
  --cluster           [required for auth] GKE cluster name. Does not have to be full name. E.g. sentry
  --sshkey            [optional] location of private ssh key

Examples:
  > ./gke.sh auth --project my-project --cluster my-cluster
  > ./gke.sh jump --project my-project
  > ./gke.sh jump --project my-project --sshkey ~/.ssh/google_compute_engine

EOF
}

function auth() {
  gcloud config set project "$1"
  local CLUSTER_ROW="$(gcloud container clusters list | grep "$2")"
  local CLUSTER_NAME=$(echo "$CLUSTER_ROW" | awk 'NR==1{ print $1 }')
  echo "CLUSTER NAME = $CLUSTER_NAME"
  local REGION=$(echo "$CLUSTER_ROW" | awk 'NR==1{ print $2 }')
  echo "Connecting to cluster $CLUSTER_NAME in region $REGION"
  gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION"
}

function jump() {
  auth "$1" horcrux
  local JUMPBOX_EXTERNAL_IP=$(gcloud compute instances list | grep jumpbox | awk '{ print $5}')
  local keyfile="$2"
  if [ "$keyfile" = "none" ]
  then
    sshuttle -r "$USER@$JUMPBOX_EXTERNAL_IP" 0.0.0.0/0 -vv
  else
    sshuttle -r "$USER@$JUMPBOX_EXTERNAL_IP" 0.0.0.0/0 -vv --ssh-cmd 'ssh -i '"$keyfile"''
  fi
}

main() {
  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  readonly subcmd="$1"
  shift

  local SSHKEY="none"

  for arg in "$@"; do
    case $arg in
    --help)
      usage
      exit 1
      ;;
    --project)
      local PROJECT="$2"
      shift
      shift
      ;;
    --cluster)
      local CLUSTER="$2"
      shift
      shift
      ;;
    --sshkey)
      SSHKEY="$2"
      shift
      shift
      ;;
    *) ;;
    esac
  done

  case $subcmd in
  auth)
    auth "$PROJECT" "$CLUSTER"
    ;;
  jump)
    jump "$PROJECT" "$SSHKEY"
    ;;
  *)
    usage
    exit 1
    ;;
  esac
}

main "$@"
