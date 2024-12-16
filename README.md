
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
 ```hcl
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
```
 - Создать отдельный сервис-аккаунт с необходимыми правами. 
 ```hcl
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
```
 - Создать региональный мастер Kubernetes с размещением нод в трёх разных подсетях.
 - Добавить возможность шифрования ключом из KMS, созданным в предыдущем домашнем задании.
 ```hcl
 # Создание ключа для шифрования
resource "yandex_kms_symmetric_key" "encryptkey" {
  name              = "encryptkey"
  default_algorithm = "AES_256"
  rotation_period   = "8760h"
}
# Создание регионального кластера k8s
resource "yandex_kubernetes_cluster" "regional_k8s" {
  name        = "regional_k8s"

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
   
    version   = "1.14"
    public_ip = true

    # maintenance_policy {
    #   auto_upgrade = true

    #   maintenance_window {
    #     day        = "monday"
    #     start_time = "15:00"
    #     duration   = "3h"
    #   }

    #   maintenance_window {
    #     day        = "friday"
    #     start_time = "10:00"
    #     duration   = "4h30m"
    #   }
    # }

    # master_logging {
    #   enabled                    = true
    #   folder_id                  = data.yandex_resourcemanager_folder.folder_resource_name.id
    #   kube_apiserver_enabled     = true
    #   cluster_autoscaler_enabled = true
    #   events_enabled             = true
    #   audit_enabled              = true
    # }
  }

  service_account_id      = yandex_iam_service_account.k8s.id
  node_service_account_id = yandex_iam_service_account.k8s.id
kms_provider {
  key_id = yandex_kms_symmetric_key.encryptkey.id
}
  # labels = {
  #   my_key       = "my_value"
  #   my_other_key = "my_other_value"
  # }

  release_channel = "STABLE"
}
```
 - Создать группу узлов, состояющую из трёх машин с автомасштабированием до шести.
 ```hcl

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
 ```
 Применил и проверяю:
 ```bash
 user@microk8s:~/clopro-homeworks-4$ yc managed-kubernetes cluster list
+----------------------+--------------+---------------------+---------+---------+------------------------+-------------------+
|          ID          |     NAME     |     CREATED AT      | HEALTH  | STATUS  |   EXTERNAL ENDPOINT    | INTERNAL ENDPOINT |
+----------------------+--------------+---------------------+---------+---------+------------------------+-------------------+
| catngd4f46pfu88q3ut3 | regional-k8s | 2024-12-13 08:17:24 | HEALTHY | RUNNING | https://130.193.58.110 | https://10.0.1.5  |
+----------------------+--------------+---------------------+---------+---------+------------------------+-------------------+

There is a new yc version '0.140.0' available. Current version: '0.139.0'.
See release notes at https://yandex.cloud/ru/docs/cli/release-notes
You can install it by running the following command in your shell:
        $ yc components update
```
 - Подключиться к кластеру с помощью `kubectl`.
```bash

user@microk8s:~/clopro-homeworks-4$ yc managed-kubernetes cluster get-credentials catngd4f46pfu88q3ut3 --external

Context 'yc-regional-k8s' was added as default to kubeconfig '/home/user/.kube/config'.
Check connection to cluster using 'kubectl cluster-info --kubeconfig /home/user/.kube/config'.

Note, that authentication depends on 'yc' and its config profile 'default'.
To access clusters using the Kubernetes API, please use Kubernetes Service Account.
user@microk8s:~/clopro-homeworks-4$ kubectl cluster-info 
Kubernetes control plane is running at https://130.193.58.110
CoreDNS is running at https://130.193.58.110/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
user@microk8s:~/clopro-homeworks-4$ kubectl get all -A
NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
kube-system   pod/coredns-577d65f588-kr4pv               1/1     Running   0          3h19m
kube-system   pod/coredns-577d65f588-pd4dd               1/1     Running   0          19m
kube-system   pod/ip-masq-agent-5tb5l                    1/1     Running   0          19m
kube-system   pod/ip-masq-agent-7qflw                    1/1     Running   0          19m
kube-system   pod/ip-masq-agent-nrpqz                    1/1     Running   0          19m
kube-system   pod/kube-dns-autoscaler-697d688488-q2xqk   1/1     Running   0          3h19m
kube-system   pod/kube-proxy-dlbzf                       1/1     Running   0          19m
kube-system   pod/kube-proxy-rwwfd                       1/1     Running   0          19m
kube-system   pod/kube-proxy-wcscg                       1/1     Running   0          19m
kube-system   pod/metrics-server-9f7b47c55-66wjh         2/2     Running   0          19m
kube-system   pod/npd-v0.8.0-q5zq9                       1/1     Running   0          19m
kube-system   pod/npd-v0.8.0-qn9np                       1/1     Running   0          19m
kube-system   pod/npd-v0.8.0-tblr9                       1/1     Running   0          19m
kube-system   pod/yc-disk-csi-node-v2-4pfwp              6/6     Running   0          19m
kube-system   pod/yc-disk-csi-node-v2-6vpj5              6/6     Running   0          19m
kube-system   pod/yc-disk-csi-node-v2-xs9tk              6/6     Running   0          19m

NAMESPACE     NAME                     TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                  AGE
default       service/kubernetes       ClusterIP   10.96.128.1    <none>        443/TCP                  3h19m
kube-system   service/kube-dns         ClusterIP   10.96.128.2    <none>        53/UDP,53/TCP,9153/TCP   3h19m
kube-system   service/metrics-server   ClusterIP   10.96.229.64   <none>        443/TCP                  3h19m

NAMESPACE     NAME                                            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                                                                        AGE
kube-system   daemonset.apps/ip-masq-agent                    3         3         3       3            3           beta.kubernetes.io/os=linux,node.kubernetes.io/masq-agent-ds-ready=true              3h19m
kube-system   daemonset.apps/kube-proxy                       3         3         3       3            3           kubernetes.io/os=linux,node.kubernetes.io/kube-proxy-ds-ready=true                   3h19m
kube-system   daemonset.apps/npd-v0.8.0                       3         3         3       3            3           beta.kubernetes.io/os=linux,node.kubernetes.io/node-problem-detector-ds-ready=true   3h19m
kube-system   daemonset.apps/nvidia-device-plugin-daemonset   0         0         0       0            0           beta.kubernetes.io/os=linux,node.kubernetes.io/nvidia-device-plugin-ds-ready=true    3h19m
kube-system   daemonset.apps/yc-disk-csi-node                 0         0         0       0            0           <none>                                                                               3h19m
kube-system   daemonset.apps/yc-disk-csi-node-v2              3         3         3       3            3           yandex.cloud/pci-topology=k8s                                                        3h19m

NAMESPACE     NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
kube-system   deployment.apps/coredns               2/2     2            2           3h19m
kube-system   deployment.apps/kube-dns-autoscaler   1/1     1            1           3h19m
kube-system   deployment.apps/metrics-server        1/1     1            1           3h19m

NAMESPACE     NAME                                             DESIRED   CURRENT   READY   AGE
kube-system   replicaset.apps/coredns-577d65f588               2         2         2       3h19m
kube-system   replicaset.apps/kube-dns-autoscaler-697d688488   1         1         1       3h19m
kube-system   replicaset.apps/metrics-server-66ddbc9fc5        0         0         0       3h19m
kube-system   replicaset.apps/metrics-server-9f7b47c55         1         1         1       19m
```
 - *Запустить микросервис phpmyadmin и подключиться к ранее созданной БД.
 - *Создать сервис-типы Load Balancer и подключиться к phpmyadmin. Предоставить скриншот с публичным адресом и подключением к БД.
 Создал манифест деплоймента и сервиса. Столкнулся с проблемой, если в пароле используются спец-символы, аутентификация не проходит.
 ```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: phpmyadmin-deployment
  labels:
    app: phpmyadmin
spec:
  replicas: 3
  selector:
    matchLabels:
      app: phpmyadmin
  template:
    metadata:
      labels:
        app: phpmyadmin
    spec:
      containers:
        - name: phpmyadmin
          image: phpmyadmin/phpmyadmin
          ports:
            - containerPort: 80
          env:
            - name: PMA_HOST
              value: "rc1a-jht0d619sr0rm739.mdb.yandexcloud.net"
            - name: PMA_PORT
              value: "3306"
            - name: PMA_PMADB
              value: "netology_db"
            - name: PMA_USER
              value: "dbuser"
            - name: PMA_PASSWORD
              value: "Password123"

---
apiVersion: v1
kind: Service
metadata:
  name: phpmyadmin-service
spec:
  type: LoadBalancer
  selector:
    app: phpmyadmin
  ports:
  - name: http
    port: 80
    targetPort: 80

 ```
```bash
user@microk8s:~/clopro-homeworks-4$ kubectl get deployments.apps 
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
phpmyadmin-deployment   3/3     3            3           103m
user@microk8s:~/clopro-homeworks-4$ kubectl get svc
NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)        AGE
kubernetes           ClusterIP      10.96.128.1     <none>            443/TCP        111m
phpmyadmin-service   LoadBalancer   10.96.220.238   158.160.138.130   80:31843/TCP   103m
user@microk8s:~/clopro-homeworks-4$ 
```
 

