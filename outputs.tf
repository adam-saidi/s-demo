output "connection_name" {
  description = "The connection string used by Cloud SQL Proxy, e.g. my-project:us-central1:my-db"
  value       = google_sql_database_instance.skydb.name
}
# database ^

output "link" {
  description = "A link to the VPC resource, useful for creating resources inside the VPC"
  value       = google_compute_network.vpc.self_link
}

output "vpcname" {
  description = "The name of the VPC"
  value       = google_compute_network.vpc.name
}

output "private_vpc_connection" {
  description = "The private VPC connection"
  value       = google_service_networking_connection.private_vpc_connection
}
# VPC ^

output "email" {
  value = "adamsaidi96@gmail.com"
}

output "private_key" {
  value     = base64decode(google_service_account_key.key.private_key)
  sensitive = true
}
# Service account key required to give appliations access to make API calls 