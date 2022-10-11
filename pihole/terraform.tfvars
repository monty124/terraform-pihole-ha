# Terraform Variables
# Customize parameters in this file specific to your deployment.

# Validate timezone correctness against 'timedatectl list-timezones' 
timezone = "Australia/Sydney"

# NETWORK CONFIGURATION PARAMETERS
# See man dhcpcd.conf for further info and examples. 
# Get these right or risk loss of network connectivity.

static_ip_v6 = "::/0"
mask = ""
static_router = ""
#we need a dns entry to download and install shit as a start
#this will be set to 127.0.0.1 as part of the terraform later
static_dns = ""

# put your ssh public key here
# you are using public and private keys to log in to ssh right..... right?
#in openssh format
public_key = ""

# generate webpassword hash with this command
# echo -n mysecretpassword | sha256sum | awk '{printf "%s",$1 }' | sha256sum
# which spits this out: c2439576ae0dd62c1a1c65cb570720db2a6963b869cec4cb6f6e2b5034692c27
webpassword = ""