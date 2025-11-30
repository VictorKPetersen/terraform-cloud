provider "google" {
  project = var.project_id
  region  = var.region
}


### VPC NETWORKS AND SUBNETWORKS ###

resource "google_compute_network" "vpc_backend_network" {
  name                    = "vpc-backend"
  auto_create_subnetworks = false 
}

# Create an IP address
resource "google_compute_global_address" "vpc_backend_private_ip_alloc" {
  name          = "backend-private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_backend_network.id
}

# Create a private connection
resource "google_service_networking_connection" "vpc_backend_network_conenction" {
  network                 = google_compute_network.vpc_backend_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.vpc_backend_private_ip_alloc.name]
}

resource "google_vpc_access_connector" "vpc-backend-connector" {
  name         = "vpc-backend-con"
  region       = var.region
  network      = google_compute_network.vpc_backend_network.name
  ip_cidr_range = "10.70.1.0/28"
  min_instances = 2
  max_instances = 10
}

resource "google_compute_subnetwork" "backend_subnetwork" {
  name          = "backend-subnet"
  ip_cidr_range = "10.20.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_backend_network.id
}

resource "google_compute_network" "vpc_frontend_network" {
  name                    = "vpc-frontend"
  auto_create_subnetworks = false 
}

resource "google_vpc_access_connector" "vpc-frontend-connector" {
  name         = "vpc-frontend-con"
  region       = var.region
  network      = google_compute_network.vpc_frontend_network.name
  ip_cidr_range = "10.60.1.0/28"
  min_instances = 2
  max_instances = 10
}

resource "google_compute_subnetwork" "frontend_subnetwork" {
  name          = "frontend-subnet"
  ip_cidr_range = "10.10.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_frontend_network.id
}

##PEERING##

resource "google_compute_network_peering" "backend_to_frontend_peer" {
  name         = "vpc-backend-to-frontend-peer"
  network      = google_compute_network.vpc_backend_network.self_link
  peer_network = google_compute_network.vpc_frontend_network.self_link
}


resource "google_compute_network_peering" "frontend_to_backend_peer" {
  name         = "vpc-frontend-to-backend-peer"
  network      = google_compute_network.vpc_frontend_network.self_link
  peer_network = google_compute_network.vpc_backend_network.self_link
}


### MODULES ##

module "backend_module" {
  source = "./modules/backend"
  region = var.region
  vpc_connecter = google_vpc_access_connector.vpc-backend-connector.id
  peering-connector = google_compute_network_peering.backend_to_frontend_peer.id
  vpc_network = google_compute_network.vpc_backend_network.self_link
}

module "frontend_module" {
  source = "./modules/frontend"
  region = var.region
  backend_url = module.backend_module.backend_instance_output
  vpc_connecter = google_vpc_access_connector.vpc-frontend-connector.id
}
