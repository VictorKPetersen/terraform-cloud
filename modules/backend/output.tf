output "backend_instance_output" {
  value       = google_cloud_run_v2_service.backend-service.uri
  description = "The google cloud run backend url"

  depends_on = [google_cloud_run_v2_service.backend-service]
}
