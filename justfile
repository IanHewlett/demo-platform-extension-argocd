#!/usr/bin/env just --justfile
podman_machine := "demo-machine"

_default:
  @just --list

demo:
  just podman
  just minikube
  just argocd

clean:
  minikube stop
  minikube delete
  podman machine stop {{podman_machine}}
  podman machine rm {{podman_machine}}

# initialize podman-machine if it does not exist, and then start the podman-machine if it is not running
@podman user="ianhewlett":
  (podman machine ls | grep -q {{podman_machine}} && [[ $? -eq 0 ]] && echo "podman machine exists") \
    || (echo "initializing podman machine" && podman machine init --cpus 6 --memory 10048 --disk-size 20 --rootful -v /Users/{{user}}:/Users/{{user}} {{podman_machine}})
  (podman machine inspect {{podman_machine}} | grep -q '"State": "running"' && [[ $? -eq 0 ]] && echo "podman machine running") \
      || (echo "starting podman machine" && podman machine start {{podman_machine}})

# start minikube if it is not running
minikube:
    @(minikube status | grep -q "Running" && [[ $? -eq 0 ]] && echo "minikube running") || \
      (echo "starting minikube" && \
        minikube start --driver=podman --container-runtime=cri-o)
    kubectl label nodes minikube "nodegroup"="management-nodes"
    kubectl label nodes minikube "node.kubernetes.io/role"="management"

argocd:
  kubectl apply -k bootstrap/argocd
  kubectl apply -f sync_secret.yaml #TODO local file to create secret with github user/secret(pat)
  kubectl apply -k bootstrap
