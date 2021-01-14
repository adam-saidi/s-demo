# create the GKE cluster in GCP and link to VPC
resource "google_container_cluster" "sky_gke" {
  name        = var.gkename
  project     = var.clusterproject
  description = "Sky Demo GCP"

  location    = var.location
  network     = google_compute_network.vpc.self_link

  initial_node_count       = var.initial_node_count

  master_auth {
    username = ""
    password = ""
    # auth disabled for demo
  }
}

# RUN THIS BEFORE T-APPLY TO GET CURRENT STATE --> terraform import google_container_cluster.sky_gke s-demo/us-central1/sky_gke
# deleting each instance is too time consuming; opportunity to automate?

# initialise first node within ske_gke cluster
resource "google_container_node_pool" "first_node" {
  name       = var.nodename
  project    = var.clusterproject
  location   = var.location
  cluster    = google_container_cluster.sky_gke.name
  node_count = 1

  node_config {
    preemptible  = true
    # set to true to increase cost savings (spot instances aws)
    machine_type = var.machine_type

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
    # required to trigger API's for monitoring and logging
  }
}

# CREATE A VPC
resource "google_compute_network" "vpc" {
  name                    = var.vpcname
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = true
}

# ALLOCATE A BLOCK OF IPV4 ADDRESSES
resource "google_compute_global_address" "private_ip_allocation" {
  name         = "private-ip-allocation"
  purpose      = "VPC_PEERING"
  address_type = "INTERNAL"
  ip_version   = "IPV4"
  prefix_length = 20
# specify the number of IP addresses Google should allocate us - atm its approx 4k based on prefix_length
  network       = google_compute_network.vpc.self_link
}

# enable private services access to allow instances deployed to use googles internal network - needed for internal IP address use (cloud SQL)
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_allocation.name]
}

# adding firewall rule to allow SSH ingress traffic - when wanting to connect into the VPC
resource "google_compute_firewall" "enable_ssh" {
  name        = "enable-ssh"
  network     = google_compute_network.vpc.name
  direction   = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["22"]
    # port 22 for SSH
  }
  target_tags = ["enable-ssh"]
#   tag used to distinguish where this firewall rule applies
}

resource "google_sql_database" "main" {
  name     = "main"
  instance = google_sql_database_instance.skydb.name
  project     = var.clusterproject
}

resource "google_sql_database_instance" "skydb" {
  name             = var.dbname
  database_version = "POSTGRES_13"
  depends_on       = [google_service_networking_connection.private_vpc_connection]
  project          = var.clusterproject

#   need to explicitly stated property to enable private connection into DB as private services access has been configured
  settings {
    tier              = "db-f1-micro"
    availability_type = "REGIONAL"
    disk_size         = 10  
    # 10 GB is the smallest disk size
    ip_configuration {
      ipv4_enabled    = false
    #   disable otherwise it'll provide the DB with a public IP

      private_network = google_compute_network.vpc.self_link
    }
  }
}

# creating a user for the database initialised
resource "google_sql_user" "db_user" {
  name     = var.user
  instance = google_sql_database_instance.skydb.name
  password = var.password
  project  = var.clusterproject
}

resource "google_project_iam_member" "skyrole" {
  role   = "roles/cloudsql.editor"
#   giving this IAM role the cloudSQL editor level of access (Read and Write access to PostgreSQL DB)
  member = "serviceAccount:${google_service_account.csql_proxy_account.email}"
}

resource "google_service_account_key" "key" {
  service_account_id = google_service_account.csql_proxy_account.name
}

# obtain reigional subnet addresses for us-central1 to setup the proxy instance
data "google_compute_subnetwork" "regional_subnet" {
  name   = google_compute_network.vpc.name
  region = "us-central1"
}

resource "google_compute_instance" "db-proxy" {
  name                      = var.proxyname
  description               = "A public-facing instance proxying traffic to skydb allowing the db to only have a private IP address, but still be reachable from outside the VPC"
  machine_type              = "f1-micro"
  zone                      = "us-central1-a"
  desired_status            = "RUNNING"
  allow_stopping_for_update = true
  
#   tag required to ensure resource is secure, where requests are filtered by firewall allowing SSH (P-22) only
  tags = ["enable-ssh"]
  
  metadata_startup_script = templatefile("run_cloud_proxy.tpl", {
    "db_instance_name"    = var.dbname,
    "service_account_key" = base64decode(google_service_account_key.key.private_key),
    })

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable" # latest stable Container-Optimized OS.
      size  = 10                     # smallest disk possible is 10 GB.
      type  = "pd-ssd"               # use SSD
    }
    
  }
  network_interface {
    network    = var.vpcname
    subnetwork = data.google_compute_subnetwork.regional_subnet.self_link
    # requred for proxy to get public facing IP address 
    access_config {}
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
  }
}

resource "google_bigquery_dataset" "sky-bigdata" {
  dataset_id                  = "example_dataset"
  description                 = "Big query dataset used for Sky demo."
  location                    = var.location
  project                     = var.clusterproject
  default_table_expiration_ms = 3600000

  labels = {
    env = "default"
  }

  access {
    role          = "roles/bigquery.dataOwner"
    user_by_email = "adamsaidi96@gmail.com"
  }
#   'Owner' could be too high to grant - Editor is enough for Read/Write access?

  access {
    role          = "roles/bigquery.dataViewer"
    user_by_email = "annassaidi99@gmail.com"
  }
#   provides access for the user to view content only, no modifications - could try members with sky.com domain?
}

# Service accounts to create both PostgreSQL database and Big Query Dataset
resource "google_service_account" "bqeditor" {
  account_id   = "bq-editor-service-account"
  display_name = "Service account for Big Query"
}

resource "google_service_account" "postgresqlservice"{
    account_id   = "postgresql-service-account"
    display_name = "Service account for Cloud SQL"
}

# creating service account to securley connect into DB from proxy
resource "google_service_account" "csql_proxy_account" {
  account_id = "cloud-sql-proxy"
  display_name = "Service account for SQL Proxy"
}