# VertiGIS Starter Kit

## Get a Linux Distribution
Request a VM from IT and install one of these:
- Debian-based:
  - Debian
  - Ubuntu
- RHEL-based:
  - Alma
  - CentOS
  - Fedora Server
  - Red Hat Enterprise
  - Open SUSE
  - SUSE Enterprise

## Notes on WSL
You may test with WSL, but WSL is not a production worthy method for running
software as contaienrs. Please make sure you use a real Linux VM and an Enterprise
grade Linux distribution.

## What you'll need (likely provided by IT)?
- SSH login credentials for the Linux VM
  - You'll need `sudo` access unless the VM is already primed for running containers.
- IP Assignment Strategy:
  - Assign Static IP/DNS for host (easiest)
  - Allocate Static IP/DNS for ingress container (advanced)
  - Allocate via DHCP (expert)
- Certificate Enrollment Details:
  - ACME Server (if available)
  - SCEP Server (if available)
  - Server Web Cert (if you cannot use ACME or SCEP)
    - `server.crt` PEM formatted
    - `server.key` PEM formatted

## Prepare your Linux Container Host
```
# SSH: Login to Server
$ ssh user@server

# Debian: Update your distribution
$ sudo apt update
$ sudo apt upgrade
$ sudo apt install git

# RHEL: Update your distribution
$ sudo dnf update
$ sudo dnf install git

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

## Get the Starter Kit Running
```
# SSH: Login to Server (port forward admin port)
$ ssh -L 127.0.0.1:8080:localhost:8080 user@server

# Get Starter Kit
$ git clone --depth 1 https://github.com/gpickell/vertigis-starter-kit
$ cd vertigis-starter-kit

# Set the password
$ docker compose run --rm editor

# Run the editor at 8080
$ docker compose up -d
```

You may now launch the editor: (here)[http://localhost:8080/]

## Updating the Starter Kit
```
$ ssh -L 127.0.0.1:8080:localhost:8080 user@server
$ cd vertigis-starter-kit
$ git pull
$ docker compose pull
$ docker compose up -d
```
