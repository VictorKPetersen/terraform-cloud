resource "google_sql_database" "database" {
  name     = "terraform-db"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_database_instance" "instance" {
  name             = "terraform-db-instance"
  region           = var.region
  database_version = "MYSQL_8_0"
  settings {
    tier = "db-f1-micro"
  }
  deletion_protection = false
}

resource "google_cloud_run_v2_service" "backend-service" {
  name     = "terraform-cloud-run-backend"
  location = var.region

  template {
    containers {
      image = "europe-west1-docker.pkg.dev/terraform-11-478207/terraform-app/terraform-app"
    }
  }

  ingress = "INGRESS_TRAFFIC_INTERNAL_ONLY"

}
