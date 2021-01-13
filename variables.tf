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