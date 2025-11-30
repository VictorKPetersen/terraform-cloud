resource "google_cloud_run_v2_service" "frontend-service" {
  name     = "terraform-cloud-run-frontend"
  location = var.region

  template {    
    vpc_access {
      connector = var.vpc_connecter
      egress = "ALL_TRAFFIC"
    } 
    containers {
      image = "europe-west1-docker.pkg.dev/terraform-11-478207/terraform-app/terraform-app-frontend"
      env {
        
        name  = "API_ADDRESS"
        value = var.backend_url
      }
    }
  }
}


resource "google_cloud_run_v2_service_iam_member" "public-access" {
  name = google_cloud_run_v2_service.frontend-service.name
  location        = google_cloud_run_v2_service.frontend-service.location
  role            = "roles/run.invoker"
  member          = "allUsers"
}