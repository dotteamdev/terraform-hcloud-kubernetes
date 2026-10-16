# Plan-only tests with mocked providers: no Hetzner resources are created.
#
#   terraform init -backend=false
#   terraform test

mock_provider "hcloud" {}
mock_provider "talos" {}
mock_provider "helm" {}
mock_provider "http" {
  mock_data "http" {
    defaults = {
      status_code   = 200
      response_body = "192.0.2.1"
    }
  }
}
mock_provider "tls" {}
mock_provider "random" {}
mock_provider "external" {}

variables {
  cluster_name = "test"
  hcloud_token = "0123456789012345678901234567890123456789012345678901234567890123"

  control_plane_nodepools = [
    { name = "control", type = "cpx22", location = "nbg1", count = 1 }
  ]
  worker_nodepools = [
    { name = "apps", type = "cpx22", location = "nbg1", count = 1 }
  ]
}

# Firewalls attached by label selector are returned by the API in firewall_ids;
# the servers must ignore them, otherwise the next apply would detach them.
run "servers_ignore_remote_firewall_ids" {
  command = plan

  assert {
    condition     = hcloud_server.control_plane["test-control-1"].ignore_remote_firewall_ids == true
    error_message = "control plane servers must set ignore_remote_firewall_ids"
  }

  assert {
    condition     = hcloud_server.worker["test-apps-1"].ignore_remote_firewall_ids == true
    error_message = "worker servers must set ignore_remote_firewall_ids"
  }
}
