provider "google" {
  version = "~> 3.42.0"
  region  = var.region
  project = var.project_id
}


resource "google_compute_network" "kcc-bootstrap" {
  name                    = "kcc-bootstrap"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "kcc-bootstrap" {
  name          = "kcc-bootstrap"
  ip_cidr_range = "10.5.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.kcc-bootstrap.self_link
  
  secondary_ip_range {
    range_name    = "kcc-bootstrap-pods"
    ip_cidr_range = "172.19.0.0/16"
  }
  secondary_ip_range {
    range_name    = "kcc-bootstrap-services"
    ip_cidr_range = "192.168.5.0/24"
  }
}

module "gke" {
  source                   = "github.com/terraform-google-modules/terraform-google-kubernetes-engine/modules/beta-public-cluster"
  project_id               = var.project_id
  name                     = "kcc-cluster"
  region                   = var.region
  network                  = google_compute_network.kcc-bootstrap.name
  subnetwork               = google_compute_subnetwork.kcc-bootstrap.name
  ip_range_pods            = "kcc-bootstrap-pods"
  ip_range_services        = "kcc-bootstrap-services"
  remove_default_node_pool = true
  service_account          = "create"
  config_connector         = true
  node_metadata            = "GKE_METADATA_SERVER"
  node_pools = [
    {
      name         = "wi-pool"
      min_count    = 1
      max_count    = 1
      machine_type = "e2-standard-4"
      auto_upgrade = true
    }
  ]
}

# example without existing KSA
module "workload_identity" {
  source              = "github.com/terraform-google-modules/terraform-google-kubernetes-engine/modules/workload-identity"
  project_id          = var.project_id
  name                = "iden-${module.gke.name}"
  namespace           = "default"
  use_existing_k8s_sa = false
}

data "google_client_config" "default" {
}

resource "google_service_account" "kcc-bootstrap" {
  account_id   = "kcc-bootstrap"
  display_name = "KCC Bootstrap"
}

resource "google_project_iam_member" "kcc-identity" {
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.kcc-bootstrap.account_id}@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "workload-identiy" {
  role    = "roles/iam.workloadIdentityUser"
  member  = "serviceAccount:${var.project_id}.svc.id.goog[cnrm-system/cnrm-controller-manager]"
}
