#!/usr/bin/env just --justfile
podman_machine := "demo-machine"
podman_mount_path := "/Users/ianhewlett:/Users/ianhewlett"

_default:
  @just --list

@demo:
  just podman
  just minikube
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
  kubectl apply -k cluster/argocd
  just _secret
  just _check
  kubectl apply -k environments/local
  just _wait

@_secret:
  kubectl create secret generic autopilot-secret -n argocd \
    --from-literal=git_username=username \
    --from-literal=git_token="$GITHUB_TOKEN" \
    --dry-run=client -o yaml | kubectl apply -f -

@_check:
  while [[ $(kubectl get pods -n argocd -l 'app.kubernetes.io/name=argocd-applicationset-controller' -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; \
   do echo "waiting for argocd-applicationset-controller pod" && sleep 1; done
  while [[ $(kubectl get pods -n argocd -l 'app.kubernetes.io/name=argocd-application-controller' -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; \
   do echo "waiting for argocd-application-controller pod" && sleep 1; done
  while [[ $(kubectl get pods -n argocd -l 'app.kubernetes.io/name=argocd-redis' -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; \
   do echo "waiting for argocd-redis pod" && sleep 1; done
  while [[ $(kubectl get pods -n argocd -l 'app.kubernetes.io/name=argocd-repo-server' -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; \
   do echo "waiting for argocd-repo-server pod" && sleep 1; done
  kubectl get pods -n argocd

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
  echo "waiting 15 seconds..." && sleep 15
  kubectl get Application -A && kubectl get ApplicationSet -A && kubectl get AppProject -A
  echo "waiting 15 seconds..." && sleep 15
  kubectl get Application -A && kubectl get ApplicationSet -A && kubectl get AppProject -A
