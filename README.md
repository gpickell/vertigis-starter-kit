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

## Preparation: Provided by IT
- SSH login credentials:
  - You'll need `sudo` access unless the VM is already primed for running containers.
- IP/DNS Assignment (for production):
  - __SIMPLE__: Assigned static IP/DNS for host.
  - __RECOMMENDED__: Assigned static IP/DNS for ingress container.
  - __ADVANCED__: DHCP-managed IP/DNS for ingress container.
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
# login to server using SSH
$ ssh containers

# Debian: update your distribution
$ sudo apt update
$ sudo apt upgrade
$ sudo apt install git

# RHEL: update your distribution
$ sudo dnf update
$ sudo dnf install git

# Docker Engine install
$ curl -fsSL https://get.docker.com -o get-docker.sh
$ sudo sh get-docker.sh

# ensure `docker` is running
$ sudo systemctl enable --now docker
$ sudo docker ps

# add yourself as to the `docker` admin
$ sudo usermod -aG docker $USER
$ logout
```

## Utility Containers

These utility containers are intended for operators who are setting up a host and need a few focused building blocks around editing, trust, certificates, networking, and DNS.

You do not need all of them.

You may want to use the [`config-editor`](utils/README.md#config-editor) if you are just getting started.

A more automated setup may also use:
- [`ca-enroll`](utils/README.md#ca-enroll) to publish a CA trust bundle
- [`cert-enroll`](utils/README.md#cert-enroll) to handle human-assisted certificate enrollment and renewal
- [`dhcp-fw`](utils/README.md#dhcp-fw) to obtain an ingress address via DHCP
- [`ns-update`](utils/README.md#ns-update) to keep DNS aligned with that address
- [`egress-fw`](utils/README.md#egress-fw) to restrict outbound TCP access



## Simple Docker Compose File
```
```

## Recommended Docker Compose File
```
```

## Advanced Docker Compose File
```
```
