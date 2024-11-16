#!/usr/bin/env bash
set -eo pipefail

COLOR='\033[0;32m' # green
NC='\033[0m' # no color

bootstrap_env="$1"
bootstrap_cluster="$2"

########################################################################################################################
echo -e "\n${COLOR}creating namespace and initial secrets${NC}"
########################################################################################################################

kubectl apply -f cluster/argocd/argocd-ns.yaml

kubectl create secret generic argocd-sync-secret -n argocd \
  --from-literal=git_username=username \
  --from-literal=git_token="$GITHUB_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic argocd-vault-plugin-credentials -n argocd \
  --from-literal=VAULT_ADDR="http://vault.vault.svc.cluster.local:8200" \
  --from-literal=AVP_TYPE="vault" \
  --from-literal=AVP_AUTH_TYPE="k8s" \
  --from-literal=AVP_K8S_MOUNT_PATH="auth/$bootstrap_cluster" \
  --from-literal=AVP_K8S_ROLE="di-admin-kubernetes-role" \
  --dry-run=client -o yaml | kubectl apply -f -

########################################################################################################################
echo -e "\n${COLOR}bootstrapping ArgoCD Core onto the cluster: $bootstrap_cluster ${NC}"
########################################################################################################################

kubectl apply -k cluster/argocd

########################################################################################################################
echo -e "\n${COLOR}waiting for the ArgoCD installation to be ready${NC}"
echo -e "${COLOR}while not strictly necessary, this reduces the wait time for the initial cluster reconciliation to sync${NC}"
########################################################################################################################

while [[ $(kubectl get pods -n argocd -l 'app.kubernetes.io/name=argocd-applicationset-controller' -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; \
  do echo "waiting for argocd-applicationset-controller pod" && sleep 1; done
while [[ $(kubectl get pods -n argocd -l 'app.kubernetes.io/name=argocd-application-controller' -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; \
  do echo "waiting for argocd-application-controller pod" && sleep 1; done
while [[ $(kubectl get pods -n argocd -l 'app.kubernetes.io/name=argocd-redis' -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; \
  do echo "waiting for argocd-redis pod" && sleep 1; done
while [[ $(kubectl get pods -n argocd -l 'app.kubernetes.io/name=argocd-repo-server' -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; \
  do echo "waiting for argocd-repo-server pod" && sleep 1; done

########################################################################################################################
echo -e "\n${COLOR}all ArgoCD pods are ready:${NC}"
########################################################################################################################

kubectl get pods -n argocd

########################################################################################################################
echo -e "\n${COLOR}applying the initial cluster sync${NC}"
echo -e "${COLOR}this applies the entire environment kustomization for convenience, but you may apply just cluster.yaml to see it automatically sync the rest of the environment${NC}"
########################################################################################################################

kubectl apply -k environments/"$bootstrap_env"/"$bootstrap_cluster"

########################################################################################################################
echo -e "\n${COLOR}complete${NC}"
########################################################################################################################
