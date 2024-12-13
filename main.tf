
# Сервисный аккаунт для управления группой В
# resource "yandex_iam_service_account" "sa-gvm" {
#   name        = "sa-gvm"
# }
# #Назначение роли для сервисного аккаунта
# resource "yandex_resourcemanager_folder_iam_member" "editor" {
#   folder_id = var.folder_id
#   role      = "editor"
#   member    = "serviceAccount:${yandex_iam_service_account.sa-gvm.id}"
# }

resource "yandex_mdb_mysql_cluster" "test_cluster" {
  name        = "test"
  environment = "PRESTABLE"
  network_id  = yandex_vpc_network.VPC.id
  version     = "8.0"

  resources {
    resource_preset_id = "s2.medium"
    disk_type_id       = "network-ssd"
    disk_size          = 20
  }

  maintenance_window {
    type = "ANYTIME"
 #   day  = "SAT"
   }
   backup_window_start {
    hours = 23
    minutes = 59

  }

  host {
    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.private_a.id
  }

  host {
    zone      = "ru-central1-b"
    subnet_id = yandex_vpc_subnet.private_b.id
  }
}

resource "yandex_vpc_network" "VPC" {
  name = var.vpc_name
}


resource "yandex_vpc_subnet" "private_a" {
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.VPC.id
  v4_cidr_blocks = ["10.1.0.0/24"]
}

resource "yandex_vpc_subnet" "private_b" {
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.VPC.id
  v4_cidr_blocks = ["10.2.0.0/24"]
}

resource "yandex_mdb_mysql_database" "netology_db" {
  cluster_id = yandex_mdb_mysql_cluster.test_cluster.id
  name       = "netology_db"
}

resource "yandex_mdb_mysql_user" "vadim" {
  cluster_id = yandex_mdb_mysql_cluster.test_cluster.id
  name       = "vadim"
  password   = "password"

  permission {
    database_name = yandex_mdb_mysql_database.netology_db.name
    roles         = ["ALL"]
  }

  permission {
    database_name = yandex_mdb_mysql_database.netology_db.name
   roles         = ["ALL", "INSERT"]
  }

  # connection_limits {
  #   max_questions_per_hour   = 10
  #   max_updates_per_hour     = 20
  #   max_connections_per_hour = 30
  #   max_user_connections     = 40
  # }

  # global_permissions = ["PROCESS"]

  # authentication_plugin = "SHA256_PASSWORD"
}

# resource "yandex_vpc_subnet" "public" {
#   name           = var.subnet_public_name
#   zone           = var.zone
#   network_id     = yandex_vpc_network.VPC.id
#   v4_cidr_blocks = ["192.168.10.0/24"]
# }


# resource "yandex_compute_instance_group" "ig-1" {
#   name                = "fixed-ig-with-balancer"
#   folder_id           = var.folder_id
#   service_account_id  = "${yandex_iam_service_account.sa-gvm.id}"
#   deletion_protection = false
#   instance_template {
#     platform_id = "standard-v1"
#     resources {
#         cores         = 2
#         memory        = 2
#         core_fraction = 20
        
#     }
#     boot_disk {
#       initialize_params {
#         image_id = "fd8ivcos71gbho9s9lcg"
#       }
#     }

#     network_interface {
#       network_id         = "${yandex_vpc_network.VPC.id}"
#       subnet_ids         = ["${yandex_vpc_subnet.public.id}"]
#     }

#     metadata = {

#       user-data = "#!/bin/bash\n cd /var/www/html\n echo \"<html><h1>Network load balanced web-server</h1><img src='https://${yandex_storage_bucket.my_bucket.bucket_domain_name}/${yandex_storage_object.picture.key}'></html>\" > index.html"
    
#       ssh-keys           = "ubuntu:${var.ssh_public_key_path}"
#     }
#   }

#   scale_policy {
#     fixed_scale {
#       size = 3
#     }
#   }

#   allocation_policy {
#     zones = [var.zone]
#   }

#   deploy_policy {
#     max_unavailable = 1
#     max_expansion   = 0
#   }
#   health_check {
#     interval = 30
#     timeout  = 10
#     tcp_options {
#       port = 80
#     }
#   }
#   load_balancer {
#     target_group_name        = "target-group"
#     target_group_description = "Целевая группа Network Load Balancer"
#   }
# }

# resource "yandex_lb_network_load_balancer" "lb-1" {
#   name = "network-load-balancer-1"

#   listener {
#     name = "network-load-balancer-1-listener"
#     port = 80
#     external_address_spec {
#       ip_version = "ipv4"
#     }
#   }

#   attached_target_group {
#     target_group_id = yandex_compute_instance_group.ig-1.load_balancer.0.target_group_id

#     healthcheck {
#       name = "http"
#       interval = 2
#       timeout = 1
#       unhealthy_threshold = 2
#       healthy_threshold = 5
#       http_options {
#         port = 80
#         path = "/index.html"
#       }
#     }
#   }
# }

