resource "google_sql_database" "database" {
  name     = "terraform-db"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_database_instance" "instance" {
  name             = "terraform-db-instance"
  region           = var.region
  database_version = "MYSQL_8_0"
  
  depends_on = [var.peering-connector]
  
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled= false
      private_network = var.vpc_network
      enable_private_path_for_google_cloud_services = false
    }
  }
  deletion_protection = false
}

resource "random_password" "pass_me_the_password" {
  length = 19
  special = true
}

resource "google_sql_user" "db-user" {
  name     = "terraform-db-user"
  instance = google_sql_database_instance.instance.name
  password = random_password.pass_me_the_password.result
}


resource "google_cloud_run_v2_service" "backend-service" {
  name     = "terraform-cloud-run-backend"
  location = var.region
  
  template {
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.instance.connection_name]
      }
    }
    vpc_access {
      connector = var.vpc_connecter
      egress = "ALL_TRAFFIC"
    } 
    containers {
      image = "europe-west1-docker.pkg.dev/terraform-11-478207/terraform-app/terraform-app"
      env {
        name = "INSTANCE_UNIX_SOCKET"
        value= "/cloudsql/terraform-11-478207:europe-west1:terraform-db-instance"
      }
      env { 
        name = "INSTANCE_CONNECTION_NAME"
        value= "terraform-11-478207:europe-west1:terraform-db-instance"
      }
      env {
        name = "DB_NAME"
        value= google_sql_database.database.name
      }
      env {
        name = "DB_USER"
        value= google_sql_user.db-user.name
      }
      env {
        name = "DB_PASS"
        value= google_sql_user.db-user.password
      }
    }
  }

  ingress = "INGRESS_TRAFFIC_INTERNAL_ONLY"
}
