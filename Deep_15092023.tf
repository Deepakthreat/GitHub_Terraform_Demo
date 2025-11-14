provider "google" {
  credentials = file("path/to/your/credentials.json")
  project     = "your-project-id"
  region      = "us-central1"
}

resource "google_compute_network" "vpc_network" {
  name                    = "my-vpc-network"
  auto_create_subnetworks = true
}

resource "google_compute_subnetwork" "web_subnet" {
  name          = "web-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_subnetwork" "app_subnet" {
  name          = "app-subnet"
  ip_cidr_range = "10.0.2.0/24"
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_subnetwork" "db_subnet" {
  name          = "db-subnet"
  ip_cidr_range = "10.0.3.0/24"
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "web_firewall" {
  name    = "web-firewall"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "app" {
  name         = "app-instance-${count.index}"
  machine_type = "n1-standard-2"
  zone         = "us-central1-a"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  
  network_interface {
    network = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.app_subnet.id
    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    echo "Hello from App Instance ${count.index}!" > /var/www/html/index.html
    nohup python -m SimpleHTTPServer 80 &
  EOF
}

resource "google_compute_backend_service" "web_backend" {
  name             = "web-backend"
  backend {
    group = google_compute_instance_group.app_group.id
  }
}

resource "google_compute_instance_group" "app_group" {
  name        = "app-group"
  description = "Instance group for the application tier"

  instances = [google_compute_instance.app.id]
}

resource "google_sql_database_instance" "database_instance" {
  name             = "my-database-instance"
  database_version = "MYSQL_5_7"
  region           = "us-central1"

  settings {
    tier = "db-n1-standard-1"
  }

  database_flags {
    name  = "skip-show-database"
    value = "1"
  }

  ip_configuration {
    ipv4_enabled    = true
    private_network = google_compute_network.vpc_network.id
  }
}


resource "google_sql_database" "database" {
  name     = "my-database"
  instance = google_sql_database_instance.database_instance.name

  charset  = "utf8"
  collation = "utf8_general_ci"
}

resource "google_sql_user" "database_user" {
  name     = "myuser"
  instance = google_sql_database_instance.database_instance.name
  password = "mypassword"
}
