variable "project_id" {}
variable "github_owner" {}
variable "github_repo" {}

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }

    google-beta = {
      source = "hashicorp/google-beta"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = "asia-northeast1"
}

provider "google-beta" {
  project = var.project_id
  region  = "asia-northeast1"
}


/* Enable APIs */

resource "google_project_service" "artifactregistry" {
  service = "artifactregistry.googleapis.com"
}

resource "google_project_service" "container" {
  service = "container.googleapis.com"
}

resource "google_project_service" "cloudbuild" {
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service" "cloudresourcemanager" {
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "iam" {
  service = "iam.googleapis.com"
}

resource "google_project_service" "pubsub" {
  service = "pubsub.googleapis.com"
}

resource "google_project_service" "run" {
  service = "run.googleapis.com"
}

resource "google_project_service" "secretmanager" {
  service = "secretmanager.googleapis.com"
}

resource "google_project_service" "spanner" {
  service = "spanner.googleapis.com"
}


/* Spanner */

resource "google_spanner_instance" "myapp" {
  name             = "myapp"
  config           = "regional-asia-northeast1"
  display_name     = "Spanner instance for Rails"
  processing_units = 100

  depends_on = [google_project_service.spanner]
}

resource "google_spanner_database" "production" {
  instance = google_spanner_instance.myapp.name
  name     = "production"
}


/* Pub/Sub */

resource "google_pubsub_topic" "default" {
  name = "default"

  depends_on = [google_project_service.pubsub]
}

resource "google_pubsub_subscription" "default-worker" {
  name  = "default-worker"
  topic = google_pubsub_topic.default.name
}


/* Artifact Registry */

resource "google_artifact_registry_repository" "myapp" {
  provider = google-beta

  location      = "asia-northeast1"
  repository_id = "myapp"
  format        = "DOCKER"

  depends_on = [google_project_service.artifactregistry]
}


/* Kubernetes Engine */

resource "google_compute_network" "myapp" {
  name                    = "myapp"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "asia-northeast1" {
  name          = google_compute_network.myapp.name
  network       = google_compute_network.myapp.name
  region        = "asia-northeast1"
  ip_cidr_range = "10.146.0.0/20"

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.147.0.0/17"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.147.128.0/22"
  }
}

resource "google_compute_router" "router" {
  name    = "router"
  network = google_compute_network.myapp.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat"
  router                             = google_compute_router.router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_container_cluster" "myapp" {
  name             = "myapp"
  enable_autopilot = true
  location         = "asia-northeast1"
  network          = google_compute_network.myapp.name
  subnetwork       = google_compute_subnetwork.asia-northeast1.name

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "10.147.132.0/28"
  }

  release_channel {
    channel = "REGULAR"
  }

  depends_on = [google_project_service.container]
}


/* Secret Manager */

resource "google_secret_manager_secret" "rails-master-key" {
  secret_id = "rails-master-key"
  replication {
    automatic = true
  }
}


/* Cloud Build */

resource "google_cloudbuild_trigger" "deploy" {
  name            = "deploy"
  service_account = google_service_account.build-deploy.id
  filename        = "cloudbuild.yaml"

  github {
    owner = var.github_owner
    name  = var.github_repo
    push {
      branch = "main"
    }
  }

  substitutions = {
    _SPANNER_INSTANCE           = google_spanner_instance.myapp.name
    _SPANNER_DATABASE           = google_spanner_database.production.name
    _SECRET_RAILS_MASTER_KEY_ID = google_secret_manager_secret.rails-master-key.secret_id
  }

  depends_on = [google_project_service.cloudbuild]
}


/* Service account for Rails app on Cloud Run */

resource "google_service_account" "myapp-main" {
  account_id = "myapp-main"

  depends_on = [google_project_service.iam]
}

resource "google_spanner_database_iam_member" "myapp-main_spanner_databaseUser" {
  instance = google_spanner_instance.myapp.name
  database = google_spanner_database.production.name
  role     = "roles/spanner.databaseUser"
  member   = "serviceAccount:${google_service_account.myapp-main.email}"
}

resource "google_pubsub_topic_iam_member" "myapp-main_pubsub_viewer" {
  topic  = google_pubsub_topic.default.name
  role   = "roles/pubsub.viewer"
  member = "serviceAccount:${google_service_account.myapp-main.email}"
}

resource "google_pubsub_topic_iam_member" "myapp-main_pubsub_publisher" {
  topic  = google_pubsub_topic.default.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${google_service_account.myapp-main.email}"
}

resource "google_secret_manager_secret_iam_member" "myapp-main_secretmanager_secretAccessor" {
  secret_id = google_secret_manager_secret.rails-master-key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.myapp-main.email}"
}


/* Service account for db:migrate and rails console */

resource "google_service_account" "myapp-dbjob" {
  account_id = "myapp-dbjob"

  depends_on = [google_project_service.iam]
}

resource "google_spanner_database_iam_member" "myapp-dbjob_spanner_databaseUser" {
  instance = google_spanner_instance.myapp.name
  database = google_spanner_database.production.name
  role     = "roles/spanner.databaseAdmin"
  member   = "serviceAccount:${google_service_account.myapp-dbjob.email}"
}

resource "google_secret_manager_secret_iam_member" "myapp-dbjob_secretmanager_secretAccessor" {
  secret_id = google_secret_manager_secret.rails-master-key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.myapp-dbjob.email}"
}

resource "google_pubsub_topic_iam_member" "myapp-dbjob_pubsub_viewer" {
  topic  = google_pubsub_topic.default.name
  role   = "roles/pubsub.viewer"
  member = "serviceAccount:${google_service_account.myapp-dbjob.email}"
}

resource "google_pubsub_topic_iam_member" "myapp-dbjob_pubsub_publisher" {
  topic  = google_pubsub_topic.default.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${google_service_account.myapp-dbjob.email}"
}

resource "google_service_account_iam_member" "myapp-dbjob_workload-identity" {
  service_account_id = google_service_account.myapp-dbjob.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[myapp/myapp-dbjob]"
}


/* Service account for worker */

resource "google_service_account" "myapp-worker-default" {
  account_id = "myapp-worker-default"

  depends_on = [google_project_service.iam]
}

resource "google_spanner_database_iam_member" "myapp-worker-default_spanner_databaseUser" {
  instance = google_spanner_instance.myapp.name
  database = google_spanner_database.production.name
  role     = "roles/spanner.databaseUser"
  member   = "serviceAccount:${google_service_account.myapp-worker-default.email}"
}

resource "google_pubsub_subscription_iam_member" "myapp-worker-default_pubsub_viewer" {
  subscription = google_pubsub_subscription.default-worker.name
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${google_service_account.myapp-worker-default.email}"
}

resource "google_pubsub_subscription_iam_member" "myapp-worker-default_pubsub_subscriber" {
  subscription = google_pubsub_subscription.default-worker.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.myapp-worker-default.email}"
}

resource "google_secret_manager_secret_iam_member" "myapp-worker-default_secretmanager_secretAccessor" {
  secret_id = google_secret_manager_secret.rails-master-key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.myapp-worker-default.email}"
}

resource "google_service_account_iam_member" "myapp-worker-default_workload-identity" {
  service_account_id = google_service_account.myapp-worker-default.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[myapp/myapp-worker-default]"
}


/* Service account for Cloud Build */

resource "google_service_account" "build-deploy" {
  account_id = "build-deploy"

  depends_on = [google_project_service.iam]
}

resource "google_project_iam_member" "build-deploy_logging_logWriter" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.build-deploy.email}"
}

resource "google_artifact_registry_repository_iam_member" "build-deploy_artifactregistry_writer" {
  provider   = google-beta
  location   = google_artifact_registry_repository.myapp.location
  repository = google_artifact_registry_repository.myapp.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.build-deploy.email}"
}

resource "google_project_iam_member" "build-deploy_container_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.build-deploy.email}"
}

resource "google_project_iam_member" "build-deploy_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.build-deploy.email}"
}

resource "google_service_account_iam_member" "build-deploy_iam_serviceAccountUser_myapp-main" {
  service_account_id = google_service_account.myapp-main.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.build-deploy.email}"
}
