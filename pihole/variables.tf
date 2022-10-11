variable "raspberrypi_ip" {
  description = "rpi current or dhcp ip address"
  type        = string
}
variable "username" {
  default = "pi"
}
variable "password" {
  description = "rpi pi user password"
  type        = string
  sensitive   = true
}
variable "new_hostname" {
  description = "New hostname, enter to retain original"
  type        = string
}
variable "new_password" {
  description = "rpi pi user new password, enter to retain current"
  type        = string
  sensitive   = true
}
variable "timezone" {}
variable "static_ip" {
  description = "rpi static ip address"
  type        = string
  }
variable "static_ip_v6" {}
variable "mask" {}
variable "static_router" {}
variable "static_dns" {}
variable "public_key" {}
variable "webpassword" {}