require 'json'

describe "argocd-core installation" do
  namespace = "argocd"
  replicas = 1
  deployment_names = %w[argocd-applicationset-controller argocd-redis argocd-repo-server]


    deployment_names.each do |deployment_name|
      describe "deployment #{deployment_name}" do
        before { `kubectl rollout status deployment #{deployment_name} -n #{namespace} --timeout=1m` }
        let(:resource) { JSON.parse(`kubectl get deployment #{deployment_name} -n #{namespace} -o json`) }

        it "has expected replicas" do
          expect(resource).to have_expected_replicas("#{replicas}".to_i)
          expect(resource).to have_expected_ready_replicas("#{replicas}".to_i)
        end
      end
    end
end
