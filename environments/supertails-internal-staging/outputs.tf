
output "load_balancer_ip" {
  value = google_compute_global_address.lb_ip.address
}

output "routes" {
  description = "URLs for each service (host-based: https://{route}.{domain}/)"
  value       = [for k in keys(var.routes) : "https://${k}.${var.domain}/"]
}

output "wildcard_domain" {
  description = "Wildcard domain for DNS: add A record *.apps.staging -> load_balancer_ip"
  value       = "*.${var.domain}"
}
