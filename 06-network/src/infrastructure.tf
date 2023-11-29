# Добавление прочих переменных

locals {
  network_name     = "my-vpc"
  subnet_name1     = "public"
  subnet_name2     = "private"
  sg_nat_name      = "nat-instance-sg"
  vm_public_name   = "test-vm-public"
  vm_private_name  = "test-vm-private"
  vm_nat_name      = "nat-instance"
  vm_nat_ip        = "192.168.10.254"
  vm_nat_image     = "fd80mrhj8fl2oe87o4e1"
  route_table_name = "nat-instance-route"
}

# Создание облачной сети

resource "yandex_vpc_network" "my-vpc" {
  name = local.network_name
}

# Создание подсетей

resource "yandex_vpc_subnet" "public-subnet" {
  name           = local.subnet_name1
  zone           = var.default_zone
  network_id     = yandex_vpc_network.my-vpc.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "private-subnet" {
  name           = local.subnet_name2
  zone           = var.default_zone
  network_id     = yandex_vpc_network.my-vpc.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.nat-instance-route.id
}

# Создание группы безопасности

resource "yandex_vpc_security_group" "nat-instance-sg" {
  name       = local.sg_nat_name
  network_id = yandex_vpc_network.my-vpc.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-http"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-https"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }
}

# Добавление готового образа ВМ

resource "yandex_compute_image" "ubuntu-1804-lts" {
  source_family = "ubuntu-1804-lts"
}

# Создание ВМ с публичным IP

resource "yandex_compute_instance" "test-vm-public" {
  name        = local.vm_public_name
  platform_id = "standard-v3"
  zone        = var.default_zone


  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = yandex_compute_image.ubuntu-1804-lts.id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet.id
    security_group_ids = [yandex_vpc_security_group.nat-instance-sg.id]
    nat                = true
  }

  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: ${var.vm_user}\n    groups: sudo\n    shell: /bin/bash\n    sudo: 'ALL=(ALL) NOPASSWD:ALL'\n    ssh-authorized-keys:\n      - ${file("${var.ssh_key_path}")}"
  }
}

# Создание ВМ с приватным IP

resource "yandex_compute_instance" "test-vm-private" {
  name        = local.vm_private_name
  platform_id = "standard-v3"
  zone        = var.default_zone

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = yandex_compute_image.ubuntu-1804-lts.id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-subnet.id
    security_group_ids = [yandex_vpc_security_group.nat-instance-sg.id]
    nat                = false
  }

  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: ${var.vm_user}\n    groups: sudo\n    shell: /bin/bash\n    sudo: 'ALL=(ALL) NOPASSWD:ALL'\n    ssh-authorized-keys:\n      - ${file("${var.ssh_key_path}")}"
  }
}

# Создание ВМ NAT

resource "yandex_compute_instance" "nat-instance" {
  name        = local.vm_nat_name
  platform_id = "standard-v3"
  zone        = var.default_zone

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = local.vm_nat_image
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet.id
    security_group_ids = [yandex_vpc_security_group.nat-instance-sg.id]
    nat                = true
    ip_address         = local.vm_nat_ip
  }

  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: ${var.vm_user_nat}\n    groups: sudo\n    shell: /bin/bash\n    sudo: 'ALL=(ALL) NOPASSWD:ALL'\n    ssh-authorized-keys:\n      - ${file("${var.ssh_key_path}")}"
  }
}

# Создание таблицы маршрутизации и статического маршрута

resource "yandex_vpc_route_table" "nat-instance-route" {
  name       = "nat-instance-route"
  network_id = yandex_vpc_network.my-vpc.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.nat-instance.network_interface.0.ip_address
  }
}
