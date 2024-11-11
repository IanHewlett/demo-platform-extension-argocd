#!/usr/bin/env bash
set -eo pipefail

bootstrap_env="$1"
COLOR='\033[0;32m'
NC='\033[0m'

echo -e "\n${COLOR}creating namespace and initial secrets${NC}"

kubectl apply -f cluster/argocd/argocd-ns.yaml

kubectl create secret generic argocd-sync-secret -n argocd \
  --from-literal=git_username=username \
  --from-literal=git_token="$GITHUB_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f cluster/argocd/argocd-vault-plugin-credentials.yaml

echo -e "\n${COLOR}bootstrapping ArgoCD Core onto the cluster: $bootstrap_env ${NC}"

kubectl apply -k cluster/argocd

echo -e "\n${COLOR}waiting for the ArgoCD installation to be ready${NC}"
echo -e "${COLOR}while not strictly necessary, this reduces the wait time for the initial cluster reconciliation to sync${NC}"

while [[ $(kubectl get pods -n argocd -l 'app.kubernetes.io/name=argocd-applicationset-controller' -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; \
  do echo "waiting for argocd-applicationset-controller pod" && sleep 1; done
while [[ $(kubectl get pods -n argocd -l 'app.kubernetes.io/name=argocd-application-controller' -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; \
  do echo "waiting for argocd-application-controller pod" && sleep 1; done
while [[ $(kubectl get pods -n argocd -l 'app.kubernetes.io/name=argocd-redis' -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; \
  do echo "waiting for argocd-redis pod" && sleep 1; done
while [[ $(kubectl get pods -n argocd -l 'app.kubernetes.io/name=argocd-repo-server' -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; \
  do echo "waiting for argocd-repo-server pod" && sleep 1; done

echo -e "\n${COLOR}all ArgoCD pods are ready:${NC}"

kubectl get pods -n argocd

echo -e "\n${COLOR}applying the initial cluster sync${NC}"
echo -e "${COLOR}this applies the entire environment kustomization for convenience, but you may apply just cluster.yaml to see it automatically sync the rest of the environment${NC}"

kubectl apply -k environments/"$bootstrap_env"

echo -e "\n${COLOR}complete${NC}"
