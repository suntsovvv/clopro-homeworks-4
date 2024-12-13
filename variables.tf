variable "cloud_id" {
  description = "ID облака"
  type        = string
}

variable "folder_id" {
  description = "ID папки"
  type        = string
}

variable "service_account_key_file" {
  description = "Путь к файлу ключа сервисного аккаунта"
  type        = string
}

variable "zone" {
  description = "Зона доступности"
  type        = string
  default     = "ru-central1-a"
}

variable "ssh_public_key_path" {
  description = "Путь к публичному SSH ключу"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "vpc_name" {
  description = "Имя виртуальной сети"
  type        = string
  default     = "VPC"
}

variable "subnet_public_name" {
  description = "Имя публичной подсети"
  type        = string
  default     = "public"
}

variable "subnet_private_name" {
  description = "Имя приватной подсети"
  type        = string
  default     = "private"
}


