terraform {
  required_providers {
    sshkey = {
      source = "daveadams/sshkey"
    }
    remote = {
      source = "tenstad/remote"
    }
  }
}



provider "remote" {

}

resource "sshkey_rsa_key_pair" "primary" {
  bits    = 4096
  comment = "${var.sudo_user}@${var.primarypi_ip}"
}

resource "sshkey_rsa_key_pair" "secondary" {
  bits    = 4096
  comment = "${var.sudo_user}@${var.secondarypi_ip}"
}

provider "remote" {
  alias = "primary"

  max_sessions = 2

  conn {
    user     = var.sudo_user
    password = var.primary_password
    host     = var.primarypi_ip

  }
}

provider "remote" {
  alias = "secondary"

  max_sessions = 2

  conn {
    user     = var.sudo_user
    password = var.secondary_password
    host     = var.secondarypi_ip

  }
}

resource "remote_file" "ssh_primary_private" {
  provider = remote.primary

  path        = "/home/pi/.ssh/id_rsa"
  content     = sshkey_rsa_key_pair.primary.private_key_pem
  permissions = "0600"

}

resource "remote_file" "ssh_primary_public" {
  provider = remote.primary

  path        = "/home/pi/.ssh/id_rsa.pub"
  content     = sshkey_rsa_key_pair.primary.public_key
  permissions = "0644"

}

resource "remote_file" "ssh_secondary_private" {
  provider = remote.secondary

  path        = "/home/pi/.ssh/id_rsa"
  content     = sshkey_rsa_key_pair.secondary.private_key_pem
  permissions = "0600"

}

resource "remote_file" "ssh_secondary_public" {
  provider = remote.secondary

  path        = "/home/pi/.ssh/id_rsa.pub"
  content     = sshkey_rsa_key_pair.secondary.public_key
  permissions = "0644"

}

resource "null_resource" "primary_gravity_sync_setup" {
  connection {
    type     = "ssh"
    user     = var.sudo_user
    password = var.primary_password
    host     = var.primarypi_ip
  }

  provisioner "file" {
    content     = templatefile("gravity-sync.conf.primary.tftpl", { secondarypi_ip = "${var.secondarypi_ip}", sudo_user = "${var.sudo_user}" })
    destination = "/home/pi/gravity-sync.conf"
  }

  provisioner "remote-exec" {
    inline = [
      #set up prereqs
      "sudo apt update && sudo apt install sqlite3 sudo git rsync ssh sshpass -y",
      "sudo mkdir /etc/gravity-sync",
      "ssh-keyscan ${var.secondarypi_ip} >> ~/.ssh/known_hosts",
      "sudo mv /home/pi/gravity-sync.conf /etc/gravity-sync/gravity-sync.conf",
      "sshpass -p ${var.secondary_password} ssh-copy-id -i /home/pi/.ssh/id_rsa.pub ${var.sudo_user}@${var.secondarypi_ip}",

      #cleanup local files in home
      "rm -f /home/pi/*",
      #install primary
      "sudo cp /home/pi/.ssh/id_rsa /etc/gravity-sync/gravity-sync.rsa",
      "sudo cp /home/pi/.ssh/id_rsa.pub /etc/gravity-sync/gravity-sync.rsa.pub",
      "sudo chown pi:pi /etc/gravity-sync/gravity-sync.rsa*",
      "export GS_INSTALL=primary && curl -sSL https://gravity.vmstan.com | sudo bash"
    ]
  }

}


resource "null_resource" "secondary_gravity_sync_setup" {
  depends_on = [
    null_resource.primary_gravity_sync_setup
  ]
  connection {
    type     = "ssh"
    user     = var.sudo_user
    password = var.secondary_password
    host     = var.secondarypi_ip
  }

  provisioner "file" {
    content     = templatefile("gravity-sync.conf.secondary.tftpl", { primarypi_ip = "${var.primarypi_ip}", sudo_user = "${var.sudo_user}" })
    destination = "/home/pi/gravity-sync.conf"
  }

  provisioner "remote-exec" {
    inline = [
      #set up prereqs
      "sudo apt update && sudo apt install sqlite3 sudo git rsync ssh sshpass -y",
      "sudo mkdir /etc/gravity-sync",
      "ssh-keyscan ${var.primarypi_ip} >> ~/.ssh/known_hosts",
      "sudo mv /home/pi/gravity-sync.conf /etc/gravity-sync/gravity-sync.conf",
      "sshpass -p ${var.primary_password} ssh-copy-id -i /home/pi/.ssh/id_rsa.pub ${var.sudo_user}@${var.primarypi_ip}",

      #cleanup local files in home
      "rm -f /home/pi/*",
      #install secondary
      "sudo cp /home/pi/.ssh/id_rsa /etc/gravity-sync/gravity-sync.rsa",
      "sudo cp /home/pi/.ssh/id_rsa.pub /etc/gravity-sync/gravity-sync.rsa.pub",
      "sudo chown pi:pi /etc/gravity-sync/gravity-sync.rsa*",
      "export GS_INSTALL=secondary && curl -sSL https://gravity.vmstan.com | sudo bash",
      "gravity-sync compare",
      "gravity-sync pull"
    ]
  }

}


resource "null_resource" "secondary_gravity_sync_enable" {

  depends_on = [
    null_resource.secondary_gravity_sync_setup
  ]
  connection {
    type     = "ssh"
    user     = var.sudo_user
    password = var.secondary_password
    host     = var.secondarypi_ip
  }

  provisioner "remote-exec" {
    inline = [
      "gravity-sync automate"
    ]
  }
}

resource "null_resource" "primary_gravity_sync_enable" {
  depends_on = [
    null_resource.secondary_gravity_sync_enable
  ]

  connection {
    type     = "ssh"
    user     = var.sudo_user
    password = var.primary_password
    host     = var.primarypi_ip
  }

  provisioner "remote-exec" {
    inline = [
      "gravity-sync automate"
    ]
  }
}

resource "null_resource" "keepalived_setup" {
  depends_on = [
    null_resource.primary_gravity_sync_enable
  ]
  for_each = {
      primary = { ssh_password = "${var.primary_password}", ssh_host = "${var.primarypi_ip}", peer_ip = "${var.secondarypi_ip}" }
      secondary = { ssh_password = "${var.secondary_password}", ssh_host = "${var.secondarypi_ip}", peer_ip = "${var.primarypi_ip}" }
  }

  connection {
    type     = "ssh"
    user     = var.sudo_user
    password = each.value.ssh_password
    host     = each.value.ssh_host
  }
  provisioner "file" {
    source      = "chk_ftl"
    destination = "/home/pi/chk_ftl"
  }

  provisioner "file" {
    content     = templatefile("keepalived_${each.key}.tftpl", { my_ip = "${each.value.ssh_host}", peer_ip = "${each.value.peer_ip}", vip = "${var.vip_address}", mask = "${var.netmask}", authpass = "${var.authpass}" })
    destination = "/home/pi/keepalived.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt install keepalived libipset13 -y",
      "sudo mkdir /etc/scripts",
      "sudo cp /home/pi/chk_ftl /etc/scripts/chk_ftl",
      "sudo chmod +x /etc/scripts/chk_ftl",
      "sudo cp /home/pi/keepalived.conf /etc/keepalived/keepalived.conf",
      "sudo systemctl enable --now keepalived.service",
      "sudo systemctl status keepalived.service --no-pager"
    ]
  }

}
