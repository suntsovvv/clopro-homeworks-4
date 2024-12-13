
# Домашнее задание к занятию «Кластеры. Ресурсы под управлением облачных провайдеров»

### Цели задания 

1. Организация кластера Kubernetes и кластера баз данных MySQL в отказоустойчивой архитектуре.
2. Размещение в private подсетях кластера БД, а в public — кластера Kubernetes.

---
## Задание 1. Yandex Cloud

1. Настроить с помощью Terraform кластер баз данных MySQL.

 - Используя настройки VPC из предыдущих домашних заданий, добавить дополнительно подсеть private в разных зонах, чтобы обеспечить отказоустойчивость. 
 - Разместить ноды кластера MySQL в разных подсетях.

 - Необходимо предусмотреть репликацию с произвольным временем технического обслуживания.
 - Использовать окружение Prestable, платформу Intel Broadwell с производительностью 50% CPU и размером диска 20 Гб.
 - Задать время начала резервного копирования — 23:59.
 - Включить защиту кластера от непреднамеренного удаления.
 Описа создание кластера с необходимыми настройками:

  ```hcl
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
  }

  host {
    zone      = "ru-central1-b"
    subnet_id = yandex_vpc_subnet.private_b.id
  }
 deletion_protection = true
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
```
- Создать БД с именем `netology_db`, логином и паролем.
```hcl
resource "yandex_mdb_mysql_database" "netology_db" {
  cluster_id = yandex_mdb_mysql_cluster.test_cluster.id
  name       = "netology_db"
}
```
Создал пользователя и назначил ему права
```hcl 
resource "yandex_mdb_mysql_user" "vadim" {
  cluster_id = yandex_mdb_mysql_cluster.test_cluster.id
  name       = "vadim"
  password   = "password"

  permission {
    database_name = yandex_mdb_mysql_database.netology_db.name
    roles         = ["ALL"]
  }
}

 ```
Применил пайплайн:
```bash
user@microk8s:~/clopro-homeworks-4$ terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_mdb_mysql_cluster.test_cluster will be created
  + resource "yandex_mdb_mysql_cluster" "test_cluster" {
      + allow_regeneration_host   = false
      + backup_retain_period_days = (known after apply)
      + created_at                = (known after apply)
      + deletion_protection       = (known after apply)
      + environment               = "PRESTABLE"
      + folder_id                 = (known after apply)
      + health                    = (known after apply)
      + host_group_ids            = (known after apply)
      + id                        = (known after apply)
      + mysql_config              = (known after apply)
      + name                      = "test"
      + network_id                = (known after apply)
      + status                    = (known after apply)
      + version                   = "8.0"

      + access (known after apply)

      + backup_window_start {
          + hours   = 23
          + minutes = 59
        }

      + host {
          + assign_public_ip   = false
          + fqdn               = (known after apply)
          + replication_source = (known after apply)
          + subnet_id          = (known after apply)
          + zone               = "ru-central1-a"
        }
      + host {
          + assign_public_ip   = false
          + fqdn               = (known after apply)
          + replication_source = (known after apply)
          + subnet_id          = (known after apply)
          + zone               = "ru-central1-b"
        }

      + maintenance_window {
          + type = "ANYTIME"
        }

      + performance_diagnostics (known after apply)

      + resources {
          + disk_size          = 20
          + disk_type_id       = "network-ssd"
          + resource_preset_id = "s2.medium"
        }
    }

  # yandex_mdb_mysql_database.netology_db will be created
  + resource "yandex_mdb_mysql_database" "netology_db" {
      + cluster_id = (known after apply)
      + id         = (known after apply)
      + name       = "netology_db"
    }

  # yandex_mdb_mysql_user.vadim will be created
  + resource "yandex_mdb_mysql_user" "vadim" {
      + authentication_plugin = (known after apply)
      + cluster_id            = (known after apply)
      + global_permissions    = (known after apply)
      + id                    = (known after apply)
      + name                  = "vadim"
      + password              = (sensitive value)

      + connection_limits (known after apply)

      + permission {
          + database_name = "netology_db"
          + roles         = [
              + "ALL",
              + "INSERT",
            ]
        }
      + permission {
          + database_name = "netology_db"
          + roles         = [
              + "ALL",
            ]
        }
    }

  # yandex_vpc_network.VPC will be created
  + resource "yandex_vpc_network" "VPC" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + folder_id                 = (known after apply)
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "VPC"
      + subnet_ids                = (known after apply)
    }

  # yandex_vpc_subnet.private_a will be created
  + resource "yandex_vpc_subnet" "private_a" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = (known after apply)
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.1.0.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

  # yandex_vpc_subnet.private_b will be created
  + resource "yandex_vpc_subnet" "private_b" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = (known after apply)
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.2.0.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-b"
    }

Plan: 6 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

yandex_vpc_network.VPC: Creating...
yandex_vpc_network.VPC: Creation complete after 3s [id=enpfi3lqt2988dptq92d]
yandex_vpc_subnet.private_a: Creating...
yandex_vpc_subnet.private_b: Creating...
yandex_vpc_subnet.private_b: Creation complete after 0s [id=e2lp142dl0r6tj1o7u4g]
yandex_vpc_subnet.private_a: Creation complete after 1s [id=e9bvep2b3qb0van406u8]
yandex_mdb_mysql_cluster.test_cluster: Creating...
...
yandex_mdb_mysql_cluster.test_cluster: Still creating... [8m20s elapsed]
yandex_mdb_mysql_cluster.test_cluster: Creation complete after 8m28s [id=c9qrk54kqcni12q1nep3]
yandex_mdb_mysql_database.netology_db: Creating...
yandex_mdb_mysql_database.netology_db: Still creating... [10s elapsed]
yandex_mdb_mysql_database.netology_db: Creation complete after 17s [id=c9qrk54kqcni12q1nep3:netology_db]
yandex_mdb_mysql_user.vadim: Creating...
yandex_mdb_mysql_user.vadim: Still creating... [10s elapsed]
yandex_mdb_mysql_user.vadim: Creation complete after 18s [id=c9qrk54kqcni12q1nep3:vadim]

Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
user@microk8s:~/clopro-homeworks-4$ 
```
![image](https://github.com/user-attachments/assets/a32e5ea1-e6fc-48d3-aa2a-170f6b6532b4)
![image](https://github.com/user-attachments/assets/92606282-9c1c-4c41-97f4-78fd673ac45b)
![image](https://github.com/user-attachments/assets/7e013eef-e7b1-48be-95d4-f177ad1824e0)


2. Настроить с помощью Terraform кластер Kubernetes.

 - Используя настройки VPC из предыдущих домашних заданий, добавить дополнительно две подсети public в разных зонах, чтобы обеспечить отказоустойчивость.
 - Создать отдельный сервис-аккаунт с необходимыми правами. 
 - Создать региональный мастер Kubernetes с размещением нод в трёх разных подсетях.
 - Добавить возможность шифрования ключом из KMS, созданным в предыдущем домашнем задании.
 - Создать группу узлов, состояющую из трёх машин с автомасштабированием до шести.
 - Подключиться к кластеру с помощью `kubectl`.
 - *Запустить микросервис phpmyadmin и подключиться к ранее созданной БД.
 - *Создать сервис-типы Load Balancer и подключиться к phpmyadmin. Предоставить скриншот с публичным адресом и подключением к БД.

Полезные документы:

- [MySQL cluster](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/mdb_mysql_cluster).
- [Создание кластера Kubernetes](https://cloud.yandex.ru/docs/managed-kubernetes/operations/kubernetes-cluster/kubernetes-cluster-create)
- [K8S Cluster](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_cluster).
- [K8S node group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_node_group).

--- 

Полезные документы:

- [Модуль EKS](https://learn.hashicorp.com/tutorials/terraform/eks).

### Правила приёма работы

Домашняя работа оформляется в своём Git репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
Файл README.md должен содержать скриншоты вывода необходимых команд, а также скриншоты результатов.
Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.
