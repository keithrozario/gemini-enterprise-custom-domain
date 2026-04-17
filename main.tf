# Backend is in a separate project
terraform {
  required_version = ">= 1.11.4"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "= 7.27.0"
    }
  }

  backend "gcs" {
    bucket = "tf-backends-krozario-gcloud"
    prefix = "terraform/state/lb-for-ge"
  }
}

provider "google" {
  region  = "us-central1"
  project = "agentspace-krozario" # project ID not the name
}

module "tf_domain_and_tls" {
  version          = "0.1.3"
  source           = "keithrozario/domain-tls/google"
  sub_domain       = "ge"
  rrdatas          = [google_compute_global_address.external_ip.address]
  record_type      = "A"
  base_domain      = "krozario.demo.altostrat.com"
  dns_project_name = "dns-krozario"
  dns_zone_name    = "krozario-demo-argolis"
  region           = "us-central1"
}


resource "google_compute_network" "agentspace_vpc" {
  name                    = "agentspace-vpc"
  auto_create_subnetworks = false
}

# Global IP Address for the Load Balancer
resource "google_compute_global_address" "external_ip" {
  name       = "external-ip"
  ip_version = "IPV4"
}

output "global_lb_ipv4" {
  value = google_compute_global_address.external_ip.address
}


# Internet NEG to proxy to vertexaisearch.cloud.google.com
resource "google_compute_global_network_endpoint_group" "agentspace_ineg" {
  name                  = "agentspace-ineg"
  network_endpoint_type = "INTERNET_FQDN_PORT"
}

resource "google_compute_global_network_endpoint" "vertex_search_endpoint" {
  global_network_endpoint_group = google_compute_global_network_endpoint_group.agentspace_ineg.name
  fqdn                          = "vertexaisearch.cloud.google.com"
  port                          = 443
}

# Backend Service for the Internet NEG
resource "google_compute_backend_service" "agentspace_ineg_bes" {
  name                  = "agentspace-ineg-bes"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"

  backend {
    group = google_compute_global_network_endpoint_group.agentspace_ineg.id
  }

  custom_response_headers = ["Strict-Transport-Security: max-age=31536000; includeSubDomains; preload"]
}

# URL Map with Rewrite according to Codelab method
resource "google_compute_url_map" "agentspace_lb" {
  name            = "agentspace-lb"
  default_service = google_compute_backend_service.agentspace_ineg_bes.id

  host_rule {
    hosts        = ["ge.krozario.demo.altostrat.com"]
    path_matcher = "agentspace-path-matcher"
  }

  path_matcher {
    name            = "agentspace-path-matcher"
    default_service = google_compute_backend_service.agentspace_ineg_bes.id

    route_rules {
      priority = 1
      match_rules {
        prefix_match = "/drive-app"
      }
      service = google_compute_backend_service.agentspace_ineg_bes.id
      route_action {
        url_rewrite {
          path_prefix_rewrite = "/home/cid/312abbc4-bc6f-4d8e-9d4f-e6650cbe9761"
          host_rewrite        = "vertexaisearch.cloud.google.com"
        }
      }
    }

    route_rules {
      priority = 2
      match_rules {
        prefix_match = "/calendar-app"
      }
      service = google_compute_backend_service.agentspace_ineg_bes.id
      route_action {
        url_rewrite {
          path_prefix_rewrite = "/home/cid/312abbc4-bc6f-4d8e-9d4f-e6650cbe9761"
          host_rewrite        = "vertexaisearch.cloud.google.com"
        }
      }
    }

    route_rules {
      priority = 3
      match_rules {
        prefix_match = "/"
      }
      service = google_compute_backend_service.agentspace_ineg_bes.id
      route_action {
        url_rewrite {
          path_prefix_rewrite = "/home/cid/312abbc4-bc6f-4d8e-9d4f-e6650cbe9761"
          host_rewrite        = "vertexaisearch.cloud.google.com"
        }
      }
    }
  }
}

# URL Map for HTTP to HTTPS Redirect
resource "google_compute_url_map" "https_redirect" {
  name = "https-redirect"

  default_url_redirect {
    https_redirect         = true
    strip_query            = false
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
  }
}

# Target HTTP Proxy for Redirect
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "http-proxy"
  url_map = google_compute_url_map.https_redirect.id
}

# Target HTTPS Proxy
resource "google_compute_target_https_proxy" "agentspace_https_proxy" {
  name            = "agentspace-https-proxy"
  url_map         = google_compute_url_map.agentspace_lb.id
  certificate_map = module.tf_domain_and_tls.ssl_certificates
}

# Global Forwarding Rule for HTTPS (Port 443)
resource "google_compute_global_forwarding_rule" "agentspace_https_fr" {
  name                  = "agentspace-https-fr"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.agentspace_https_proxy.id
  ip_address            = google_compute_global_address.external_ip.id
}

# Global Forwarding Rule for HTTP (Port 80)
resource "google_compute_global_forwarding_rule" "agentspace_http_fr" {
  name                  = "agentspace-http-fr"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_proxy.id
  ip_address            = google_compute_global_address.external_ip.id
}
