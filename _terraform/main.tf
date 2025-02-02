terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    ansible ={
      source = "ansible/ansible"
    }
  }
}

provider "yandex" {
  zone = "ru-central1-b"
}

resource "yandex_container_registry" "test" {
  name = "test"
}

resource "yandex_container_registry_iam_binding" "test" {
  registry_id = yandex_container_registry.test.id
  role = "container-registry.viewer"
  members = ["system:allUsers"]
}

resource "yandex_compute_instance" "vm" {
  name = "vm"
  platform_id = "standard-v1"
  boot_disk {
    initialize_params {
      image_id = "fd81vb9fms9e4l78tmhr" # almalinux-9-v20250127
      size = 16
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat = true
  }

  resources {
    core_fraction = 20
    cores = 2
    memory = 2
  }

  metadata = { user-data = "${file("users.yml")}" }
  allow_stopping_for_update = true
}

resource "yandex_vpc_network" "network1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet1" {
  name = "subnet1"
  v4_cidr_blocks = [ "172.20.0.0/24" ]
  network_id = yandex_vpc_network.network1.id
}

resource "ansible_host" "vm" {
  name = "vm"
  groups = ["all"]
  variables = {
    ansible_host = yandex_compute_instance.vm.network_interface.0.nat_ip_address
  }
}

output "vm-ip" {
  value = yandex_compute_instance.vm.network_interface.0.nat_ip_address
}

output "registry" {
  value = yandex_container_registry.test.id
}
