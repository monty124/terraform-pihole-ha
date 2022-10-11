variable "primarypi_ip" {
  description = "rpi primary pihole ip address"
  type        = string
}
variable "secondarypi_ip" {
  description = "rpi secondary pihole ip address"
  type        = string
}

variable "vip_address" {
  description = "rpi VIP ip address"
  type        = string
}

variable "sudo_user" {
  default = "pi"
}

variable "authpass" {
  description = "A keepalived auth password max 8 characters"
}

variable "primary_password" {
  description = "rpi primary pi user password"
  type        = string
  sensitive   = true
}

variable "secondary_password" {
  description = "rpi secondary pi user password"
  type        = string
  sensitive   = true
}


variable "netmask" {
default = "24"
}