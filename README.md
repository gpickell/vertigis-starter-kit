# VertiGIS Starter Kit

## Get a Linux Distribution
Request a VM from IT and install one of these:
- Debian-based:
  - Debian
  - Ubuntu __RECOMMENDED__
- RHEL-based:
  - Alma
  - CentOS
  - Fedora Server
  - Red Hat Enterprise
  - Open SUSE
  - SUSE Enterprise

## Preperation: Provided by IT
- SSH login credentials:
  - You'll need `sudo` access unless the VM is already primed for running containers.
- IP/DNS Assignment (for production):
  - __SIMPLE__: Assigned static IP/DNS for host.
  - __ADVANCED__: Assigned static IP/DNS for ingress container. __RECOMMENDED__
  - __EXPERT__: DHCP-managed IP/DNS for ingress container.
- Certificate Enrollment:
  - ACME Server (if available)
  - CERTSRV Server (if available)
  - Server Web Cert (if ACME or CERTSRV are unavailable)
    - `server.crt` PEM formatted
    - `server.key` PEM formatted


## Notes on WSL
You may test with WSL, but WSL is not a production worthy method for running
software as contaienrs. Please make sure you use a real Linux VM and an Enterprise
grade Linux distribution.


## Notes for Hyper/V 
- Enable interface sharing: `Set-VMNetworkAdapter -MacAddressSpoofing On`
- Create an external virtual switch for the VM.


## Modify your SSH Configuration `~/.ssh/config`
Configure the SSH connection for your system:
```
Host containers
    HostName containers-host-01.contoso.com
    User gary
    LocalForward 127.0.0.1:8080 127.0.0.1:8080    
```


## Prepare your Linux Container Host
```
# SSH: Login to Server
$ ssh containers

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

You may now launch the editor: [here](http://localhost:8080/)

## Updating the Starter Kit
```
$ ssh containers
$ cd vertigis-starter-kit
$ git pull
$ docker compose pull
$ docker compose up -d
```

## Simple Docker Compose File
```
```

## Expert Docker Compose File
```
```
