variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "custom_domain" {
  description = "The full source FQDN for the load balancer (e.g., ge.example.com)"
  type        = string
}

variable "dns_project_name" {
  description = "The project name where DNS zone is hosted"
  type        = string
}

variable "dns_zone_name" {
  description = "The name of the DNS zone"
  type        = string
}

variable "target_fqdn" {
  description = "The FQDN of the target service"
  type        = string
  default     = "vertexaisearch.cloud.google.com"
}

variable "agentspace_app_path" {
  description = "The path prefix to rewrite to"
  type        = string
}
