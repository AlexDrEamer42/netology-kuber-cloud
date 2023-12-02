resource "yandex_iam_service_account" "ig-sa" {
  name        = "ig-sa"
  description = "service account to manage IG"
}

resource "yandex_resourcemanager_folder_iam_member" "admin" {
  folder_id = var.folder_id
  role      = "admin"
  member    = "serviceAccount:${yandex_iam_service_account.ig-sa.id}"
}

resource "yandex_compute_instance_group" "ig-1" {
  name                = "fixed-ig-with-balancer"
  folder_id           = var.folder_id
  service_account_id  = "${yandex_iam_service_account.ig-sa.id}"
  deletion_protection = false
  instance_template {
    platform_id = "standard-v3"
    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = "fd827b91d99psvq5fjit"
      }
    }

    network_interface {
      network_id = "${yandex_vpc_network.my-vpc.id}"
      subnet_ids = ["${yandex_vpc_subnet.public-subnet.id}"]
    }

    metadata = {
      ssh-keys = "${var.vm_user}:${file("~/.ssh/id_rsa.pub")}"
      user-data = "#cloud-config\nbootcmd:\n  - cd /var/www/html && echo '<html><h1><a href=https://storage.yandexcloud.net/alex-021223/picture.jpg><img src=https://storage.yandexcloud.net/alex-021223/picture.jpg></a></h1></html>' > index.html"
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = [var.default_zone]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }

  load_balancer {
    target_group_name        = "target-group"
    target_group_description = "load balancer target group"
  }
}

resource "yandex_lb_network_load_balancer" "lb-1" {
  name = "network-load-balancer-1"

  listener {
    name = "network-load-balancer-1-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.ig-1.load_balancer.0.target_group_id

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/index.html"
      }
    }
  }
}
