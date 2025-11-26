module "backend_module" {
  source = "../backend"
}

resource "google_cloud_run_service" "frontend-service" {
  name     = "terraform-cloud-run-frontend"
  location = var.region

  template {
    spec {
      containers {
        image = "europe-west1-docker.pkg.dev/terraform-11-478207/terraform-app/terraform-app-frontend"
        env {
          name  = "API_ADDRESS"
          value = module.backend_module.backend_instance_output
        }
      }
    }
  }

  depends_on = [ module.backend_module.backend_instance_output ]
}

