# demo-platform-extension-argocd

This bootstraps [ArgoCD core](https://argo-cd.readthedocs.io/en/stable/operator-manual/core/) onto target clusters.

ArgoCD core contains the CRDs, Controllers for those CRDs, the Repository Server, and a Redis Server.

ArgoCD core does not install the API Server, the Notifications Controller, or the External Authorization (dex) Server.

CRDS:
1. Application
2. ApplicationSet
3. AppProject

Bootstrap Process:
1. Before ArgoCD can be used to monitor repositories for cluster configurations, it must first exist on the cluster.
2. Once ArgoCD is installed, it needs to initially be told something to sync to.

Useful commands:
'kubectl get Application -A && kubectl get ApplicationSet -A && kubectl get AppProject -A'
'argocd admin dashboard -n argocd'

ArgoCD Application:
- You can pass values to a helm chart through an Application in three ways:
  1) valuesFiles
  2) values
  3) parameters
  - with the order of precedence being that parameters override values and values override valuesFiles

Namespace Management:
- Namespaces can be created by the ArgoCD Application by specifying 'CreateNamespace=true' in spec/syncPolicy/syncOptions
- Labels and Annotations can be added to the automatically created namespace by through spec/syncPolicy/managedNamespaceMetadata

[ArgoCD Vault Plugin](https://argocd-vault-plugin.readthedocs.io/en/stable/):
- Used to post-render the result of helm-template or kustomize-build with the values of secrets retrieved from vault
