require 'json'
require 'base64'

module Matchers
  RSpec::Matchers.define :have_expected_replicas do | count |
    match { |x| x.dig('status', 'replicas') == count }
  end

  RSpec::Matchers.define :have_expected_ready_replicas do | count |
    match { |x| x.dig('status', 'readyReplicas') == count }
  end

  RSpec::Matchers.define :have_expected_chart_version do | chart_name, chart_version |
    match { |x| x.dig('metadata', 'labels', 'helm.sh/chart') == "#{chart_name}-#{chart_version}" }
  end

  RSpec::Matchers.define :run_on_node_group do |group|
    match { |x| JSON.parse(`kubectl get nodes #{x.dig('spec', 'nodeName')} -o json`).dig('metadata', 'labels', 'nodegroup') == group }
  end

  RSpec::Matchers.define :be_unique do
    match { |x| x.uniq }
    failure_message { |x| "expect all elements to be unique, but found #{x}" }
  end

  RSpec::Matchers.define :match_certificate do |actual_key, vault_cert, expected_key|
    match do |certificate|
      Base64.decode64(certificate.dig('data', actual_key)) == vault_cert.dig('data', 'data', expected_key)
    end

    failure_message { "#{actual_key} does not match #{expected_key}" }
  end

  RSpec::Matchers.define :have_sidecar_running do |sidecar_name, namespace|
    match do |x|
      pod = JSON.parse(`kubectl get pod -n #{namespace} -l app=#{x} -o json`).dig('items').first
      sidecar = pod.dig('status', 'containerStatuses').select { |y| y.dig('name') == sidecar_name }.first

      sidecar != nil &&
        sidecar.dig('ready') == true
    end

    failure_message { |x| "#{sidecar_name} does not exist on app #{x}" }
  end
end
