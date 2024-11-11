#!/usr/bin/env just --justfile
podman_machine := "demo-machine"
podman_mount_path := "/Users/ianhewlett:/Users/ianhewlett"

_default:
  @just --list

@demo:
  just podman
  just minikube
  just vault
  just argocd

@clean:
  minikube stop || true
  minikube delete || true
  podman machine stop {{podman_machine}} || true
  podman machine rm {{podman_machine}} --force || true

# initialize podman-machine if it does not exist, and then start the podman-machine if it is not running
@podman:
  (podman machine ls | grep -q {{podman_machine}} && [[ $? -eq 0 ]] && echo "podman machine exists") \
    || (echo "initializing podman machine" && podman machine init --cpus 6 --memory 10048 --disk-size 20 --rootful -v {{podman_mount_path}} {{podman_machine}})
  (podman machine inspect {{podman_machine}} | grep -q '"State": "running"' && [[ $? -eq 0 ]] && echo "podman machine running") \
      || (echo "starting podman machine" && podman machine start {{podman_machine}})

# start minikube if it is not running
@minikube:
    (minikube status | grep -q "Running" && [[ $? -eq 0 ]] && echo "minikube running") || \
      (echo "starting minikube" && \
        minikube start --driver=podman --container-runtime=cri-o)
    kubectl label nodes minikube "nodegroup"="management-nodes"
    kubectl label nodes minikube "node.kubernetes.io/role"="management"

@argocd:
  ./scripts/bootstrap.sh local-minikube-us-east-0
  just _wait

@_wait:
  kubectl get Application -A && kubectl get ApplicationSet -A && kubectl get AppProject -A
  echo "waiting 5 seconds..." && sleep 5
  kubectl get Application -A && kubectl get ApplicationSet -A && kubectl get AppProject -A
  echo "waiting 5 seconds..." && sleep 5
  kubectl get Application -A && kubectl get ApplicationSet -A && kubectl get AppProject -A
  echo "waiting 5 seconds..." && sleep 5
  kubectl get Application -A && kubectl get ApplicationSet -A && kubectl get AppProject -A
  echo "waiting 5 seconds..." && sleep 5
  kubectl get Application -A && kubectl get ApplicationSet -A && kubectl get AppProject -A
  echo "waiting 10 seconds..." && sleep 10
  kubectl get Application -A && kubectl get ApplicationSet -A && kubectl get AppProject -A
  echo "waiting 10 seconds..." && sleep 10
  kubectl get Application -A && kubectl get ApplicationSet -A && kubectl get AppProject -A
  echo "waiting 10 seconds..." && sleep 10
  kubectl get Application -A && kubectl get ApplicationSet -A && kubectl get AppProject -A

extract-argocd-core-manifests:
  mkdir -p ./tmp
  kustomize build cluster/argocd -o ./tmp

vault vault_namespace="vault": && vault-auth vault-secrets
  helm repo add hashicorp https://helm.releases.hashicorp.com && helm repo update > /dev/null
  kubectl create namespace {{vault_namespace}} --dry-run=client -o yaml | kubectl apply -f -
  helm upgrade -i vault "hashicorp/vault" -n {{vault_namespace}} \
    --set "server.dev.enabled=true" \
    --set "server.image.repository=docker.io/hashicorp/vault" \
    --set "injector.image.repository=docker.io/hashicorp/vault-k8s" \
    --wait

vault-auth vault_namespace="vault":
  while [[ $(kubectl get pods -n {{vault_namespace}} vault-0 -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; \
   do echo "waiting for pod" && sleep 1; done
  envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ./scripts/vault-auth.sh > tmp.sh
  kubectl -n {{vault_namespace}} exec -it vault-0 -- /bin/sh -c  "`cat tmp.sh`"
  rm -f tmp.sh

vault-secrets vault_namespace="vault":
  while [[ $(kubectl get pods -n {{vault_namespace}} vault-0 -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; \
   do echo "waiting for pod" && sleep 1; done
  envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ./scripts/vault-secrets.sh > tmp.sh
  kubectl -n {{vault_namespace}} exec -it vault-0 -- /bin/sh -c  "`cat tmp.sh`"
  rm -f tmp.sh

test-vault-plugin:
  kubectl apply -f test/e2e/argocd-vault-plugin/sample-secret.yaml
  # get application; is healthy?
  # get secret; has value?
