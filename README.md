# VertiGIS Starter Kit

## Get a Linux Distribution
Request a VM from IT and install one of these:
- Debian-based:
  - Debian
  - Ubuntu
- RHEL-based:
  - Alma
  - Fedora Server
  - Red Hat Enterprise
- SUSE-based:
  - Open SUSE
  - SUSE Enterprise

## Prepare your Linux Container Host
```
# SSH: Login to 
$ ssh user@server

# RHEL: Update your distribution
$ sudo dnf update

# Debian: Update your distribution
$ sudo apt update
$ sudo apt upgrade

# Get Docker Engine
$ curl -fsSL https://get.docker.com -o get-docker.sh
$ sudo sh get-docker.sh

# Ensure Docker is running
$ sudo systemctl enable --now docker
$ sudo docker ps

# Add yourself as docker admin
$ sudo usermod -aG docker $USER
$ logout
```

