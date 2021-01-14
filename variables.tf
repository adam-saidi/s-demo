// Configure the Google Cloud provider - need this for credentials!
provider "google" {
  credentials = file("s-demo-2944d21e7a62.json")
  project     = "deft-upgrade-301212"
  region      = "us-west1"
}

variable "user" {
    default = "new-job-adam"
    description = "PostgreSQL database User Account"
}

variable "dbname" {
    default = "database-sky"
}

variable "clusterproject" {
    default = "deft-upgrade-301212"
}

variable "vpcname" {
    default = "sky-demo-vpc"
    description = "Name of allocated VPC in GCP"
}

variable "nodename" {
    default = "my-first-node"
}

variable "password" {
    default = "sky-adam"
    sensitive = true
# hides the value in GCP GUI
    description = "password - shouldnt be shared!!"
}

variable "proxyname" {
    default = "sky-proxy"
}

variable "gkename" {
  default = "sky-gke"
}

variable "project" {
  default = "s-demo"
}

variable "location" {
  default = "us-central1"
}

variable "initial_node_count" {
  default = 1
}

variable "machine_type" {
  default = "n1-standard-1"
  # 1vCPU + 3.75gb memory - smallest machine type
}

# gcloud beta compute ssh --zone "us-central1-a" "sky-proxy" --project "deft-upgrade-301212"

# ssh -t adamsaidi@34.67.9.167 docker run --rm --network=host -t postgres:13-alpine psql -U postgres -h localhost