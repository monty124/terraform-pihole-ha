# Terraform for Pihole & Pihole Gravity Sync

## What the hell is this?

Some Terraform to auto deploy Pihole and Pihole HA using Gravity Sync.

It could probably use a clean up in areas but it works

It is only designed for deployment and not maintenance, so fire once only!

## Whats PiHole?

Take a look [here](https://github.com/pi-hole/pi-hole)

## Whats Pihole Gravity Sync

and [here](https://github.com/vmstan/gravity-sync)

## Caveats

- Run DHCP elsewhere (for now, for ... reasons) well for one you want your DHCP DNS referance to be the pihole VIP HA address, this can't be done via the GUI in pihole, more info [here](https://github.com/vmstan/gravity-sync/wiki/DHCP-Replication). It can be done, I just have not done it... yet
- You have to set each piholes upstream dns independantly
- see any [limitations](https://github.com/vmstan/gravity-sync#limitations) listed at the pihole gravity sync git linked above
- the Pihole terraform is not catering for multiple hosts, handle your state files and use out files OR use [workspaces](https://www.terraform.io/language/state/workspaces) or if you dont care, just delete your terraform.tfstate statefiles in between multiple runs! still use the -out files but!!

example:

```
    terraform plan -out=pihole1

    terraform apply ".\pihole1" -state=pihole1.tfstate
```


## How to use

You need a bit of understanding on how terraform works, basic instructions below, don't worry Terraform will prompt you for missing info, just make sure you read everything!

### Install Terraform

The easiest way is to use winget

```
    winget install terraform
```
I also recommend Powershell 7 and Windows Terminal

### Prepare your pihole SD cards

- download and install [RPI Imager](https://downloads.raspberrypi.org/imager/imager_latest.exe)
- open imager
- select your OS --> RPI Other --> RPI OS Lite 64bit (or a compatible image for your PI, always use a lite OS)
- choose your storage card
- click the cog
- set a hostname
- enable ssh and set a password (keep the pi username)
- set the locale
-  burn the image and throw into your pi!

Rinse and Repeat if needed!

### Pihole

!! Remember your workspace or terraform state files !!

- Pull the repo
- cd into the pihole dir
- read and edit the terraform.tfvars file, you will need to fill out the empty parameters! 
- setup terraform
```
    terraform init
```
- plan your deployment and answer the questions
```
    terraform plan -out=pihole1
```
- review the plan
- Apply the config
```
    terraform apply ".\pihole1"
    or
    terraform apply ".\pihole1" -state=pihole1.tfstate
```
- review and make sure it worked!

Rinse and Repeat if needed!

### Pihole-HA

This requires 2 piholes installed, if your using the terraform above that will be sufficient!

This Terraform will apply to both pi's at the same time! no need to manage statefile or workspaces here

It will also prompt for all missing information, no tfvars file editing needed

- Pull the repo
- cd into the pihole-HA dir
- setup terraform
```
    terraform init
```
- plan your deployment and answer the questions
```
    terraform plan -out=piholeha
```
- review the plan
- Apply the config
```
    terraform apply ".\piholeha"
```
- review and make sure it worked!   


# Something went wrong!

ahh you're a little on your own here! No warranty soz, this has been mostly tested and is working but updates may break shit!


### Referances

initial terraform files were taken from https://github.com/clayshek/terraform-raspberrypi-bootstrap 