provider "google" {
  project = var.project_id
  region  = var.region
}

module "backend_module" {
  source = "./modules/backend"
  region = var.region
}

module "frontend_module" {
  source = "./modules/frontend"
  region = var.region
}
