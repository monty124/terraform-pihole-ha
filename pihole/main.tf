# Raspberry Pi PiHole Terraform Provisioner (Tested with Raspbian Bullseye).
# This is a run-once bootstrap Terraform provisioner for a Raspberry Pi to install PiHole.  
# Provisioners by default run only at resource creation, additional runs without cleanup may introduce problems.
# https://www.terraform.io/docs/provisioners/index.html


resource "null_resource" "raspberry_pi_bootstrap" {
  connection {
    type     = "ssh"
    user     = var.username
    password = var.password
    host     = var.raspberrypi_ip
  }


  provisioner "remote-exec" {
    inline = [
      #SET Public Key
      "mkdir /home/pi/.ssh",
      "chmod 700 /home/pi/.ssh",
      "echo ${var.public_key} >> /home/pi/.ssh/authorized_keys",
      "chmod 640 /home/pi/.ssh/authorized_keys",
      #add pi to sudoers to prevent asking for password when sudoing for some reason the ssh key was not consistent
      "echo ${var.password} | sudo -S echo \"pi ALL=(ALL:ALL) NOPASSWD:ALL\" >> /etc/sudoers.d/010_pi-nopasswd",
      "echo ${var.password} | sudo -S shutdown -r +0"

    ]
  }


  provisioner "remote-exec" {
    inline = [
      # DATE TIME CONFIG
      "sudo timedatectl set-timezone ${var.timezone}",
      "sudo timedatectl set-ntp true",

      # SYSTEM AND PACKAGE UPDATES
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",
      "date",
      # uncomment to upgrade distribution
      #"sudo apt-get dist-upgrade -y",
      #"sudo apt --fix-broken install -y",

      # NETWORKING - SET STATIC IP
      "echo 'interface eth0\nstatic ip_address=${var.static_ip}/${var.mask}\nstatic routers=${var.static_router}\nstatic domain_name_servers=${var.static_dns}' | cat >> /etc/dhcpcd.conf",

      # OPTIMIZE GPU MEMORY
      "echo 'gpu_mem=16' | sudo tee -a /boot/config.txt",

      #PrepPiHole
      "sudo mkdir /etc/pihole",
      "sudo chmod -R 775 /etc/pihole",
      # REBOOT
      # Changed from 'sudo reboot' to 'sudo shutdown -r +0' to address exit status issue encountered
      # after Terraform 0.11.3, see https://github.com/hashicorp/terraform/issues/17844
      "sudo -S shutdown -r +0"
    ]

  }
}


resource "null_resource" "additional_config" {
  #continue configuration connect using new ip and or creds

  depends_on = [
    null_resource.raspberry_pi_bootstrap
  ]

  provisioner "file" {
    content     = templatefile("pihole.conf.tftpl", { webpassword = "${var.webpassword}", static_ip_and_mask = "${var.static_ip}\\${var.mask}", static_ip_v6 = "${var.static_ip_v6}" })
    destination = "/home/pi/setupVars.conf"
  }

  provisioner "remote-exec" {
    inline = [
      #Install PiHole
      "sudo mv /home/pi/setupVars.conf /etc/pihole/setupVars.conf",
      "cd /home/pi",
      "wget -O basic-install.sh https://install.pi-hole.net",
      "sudo bash basic-install.sh --unattended",
      #Cleanup
      "rm -rf /tmp/*",
      "rm -rf /home/pi/*",
      #Print the setup vars for referance
      "sudo cat /etc/pihole/setupVars.conf",
      #change dns to look at itself! 
      "sudo sed -i 's/static domain_name_servers=${var.static_dns}/static domain_name_servers=127.0.0.1/g' /etc/dhcpcd.conf"
    ]
  }

  connection {
    type     = "ssh"
    host     = var.static_ip
    user     = var.username
    password = var.password
  }
}

resource "null_resource" "change_hostname" {
  count = var.new_hostname != "" ? 1 : 0
  
  depends_on = [
    null_resource.raspberry_pi_bootstrap
  ]

provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ${var.new_hostname}",
      "echo '127.0.1.1 ${var.new_hostname}' | sudo tee -a /etc/hosts" 
    ]
  }

connection {
    type     = "ssh"
    host     = var.static_ip
    user     = var.username
    password = var.password
  }

}


resource "null_resource" "change_password" {
  count = var.new_password != "" ? 1 : 0
  
  depends_on = [
    null_resource.additional_config
  ]
  
  provisioner "remote-exec" {
    inline = [
      "echo 'pi:${var.new_password}' | sudo chpasswd"    
    ]
  }
  connection {
    type     = "ssh"
    host     = var.static_ip
    user     = var.username
    password = var.password
  }

}
