


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
   }
   backup_window_start {
    hours = 23
    minutes = 59

  }

  host {
    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.private_a.id
    assign_public_ip = false
  }

  host {
    zone      = "ru-central1-b"
    subnet_id = yandex_vpc_subnet.private_b.id
    assign_public_ip = false
  }
  
 # deletion_protection = true
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

resource "yandex_vpc_subnet" "public_a" {
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.VPC.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}

resource "yandex_vpc_subnet" "public_b" {
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.VPC.id
  v4_cidr_blocks = ["10.0.2.0/24"]
}
resource "yandex_vpc_subnet" "public_d" {
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.VPC.id
  v4_cidr_blocks = ["10.0.3.0/24"]
}

# Сервисный аккаунт 
resource "yandex_iam_service_account" "k8s" {
  name        = "k8s"
}

#Назначение роли для сервисного аккаунта
resource "yandex_resourcemanager_folder_iam_member" "editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}
#Создание статического ключа доступа
resource "yandex_iam_service_account_static_access_key" "k8s-key" {
  service_account_id = yandex_iam_service_account.k8s.id
  description        = "static access key for object storage"
}



resource "yandex_mdb_mysql_database" "netology_db" {
  cluster_id = yandex_mdb_mysql_cluster.test_cluster.id
  name       = "netology_db"
}

resource "yandex_mdb_mysql_user" "dbuser" {
  cluster_id = yandex_mdb_mysql_cluster.test_cluster.id
  name       = "dbuser"
  password   = "Password123"
  permission {
    database_name = yandex_mdb_mysql_database.netology_db.name
    roles         = ["ALL"]
  }
  global_permissions = ["PROCESS"]
}
# Создание ключа для шифрования
resource "yandex_kms_symmetric_key" "encryptkey" {
  name              = "encryptkey"
  default_algorithm = "AES_256"
}
# Создание регионального кластера k8s
resource "yandex_kubernetes_cluster" "regional-k8s" {
  name        = "regional-k8s"

  network_id = yandex_vpc_network.VPC.id

  master {
    regional {
      region = "ru-central1"

      location {
        zone      = yandex_vpc_subnet.public_a.zone
        subnet_id = yandex_vpc_subnet.public_a.id
      }

      location {
        zone      = yandex_vpc_subnet.public_b.zone
        subnet_id = yandex_vpc_subnet.public_b.id
      }

      location {
        zone      = yandex_vpc_subnet.public_d.zone
        subnet_id = yandex_vpc_subnet.public_d.id
      }
    }
   
    version   = "1.30"
    public_ip = true

  }

  service_account_id      = yandex_iam_service_account.k8s.id
  node_service_account_id = yandex_iam_service_account.k8s.id
kms_provider {
  key_id = yandex_kms_symmetric_key.encryptkey.id
}
  release_channel = "STABLE"
}
 resource "yandex_kubernetes_node_group" "k8s-node-group-a" {
  cluster_id  = yandex_kubernetes_cluster.regional-k8s.id
  name        = "k8s-node-group-a"

  version     = "1.30"

  labels = {
    "key" = "k8s-node-group-a"
  }

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat        = true
      subnet_ids = ["${yandex_vpc_subnet.public_a.id}"]
       }

    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    scheduling_policy {
      preemptible = true
    }

    container_runtime {
      type = "containerd"
    }
      metadata = {
        ssh-keys  = "ubuntu:${var.ssh_public_key_path}"
    }
  }

  scale_policy {
    auto_scale {
      initial = 3
      min = 3
      max = 6
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
 
    }
    
  }

  
}

