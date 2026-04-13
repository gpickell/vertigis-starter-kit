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

## Notes on WSL
You may test with WSL, but WSL is not a production worthy method for running
software. Please make sure you use a real Linux VM and enterprise grade Linux distribution.

## Information and actions to request from IT
- SSH login credentials for the Linux VM (for yourself)
- IP Assignment:
  - Assign Static IP/DNS for host (easiest)
  - Allocate Static IP/DNS for ingress container (advanced)
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

# RHEL: Update your distribution
$ sudo dnf update

# SUSE: Update your distribution
$ sudo dnf update

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

# Starter Kit (set password)
$ docker compose -f https://github.com/gpickell/vertigis-starter-kit run 
```

