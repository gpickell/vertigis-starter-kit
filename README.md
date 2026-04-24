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
software as containers. Please make sure you use a real Linux VM and an Enterprise
grade Linux distribution.


## Notes for Hyper/V 
- Enable interface sharing: `Set-VMNetworkAdapter -MacAddressSpoofing On`
- Create an external virtual switch for the VM.


## Modify your SSH Configuration `~/.ssh/config`
Configure the SSH connection for your system:
```ssh-config
Host containers
    HostName containers-host-01.contoso.com
    User gary
    LocalForward 127.0.0.1:8080 127.0.0.1:8080    
```


## Prepare your Linux Container Host
```bash
# login to server using SSH
ssh containers

# Debian: update your distribution
sudo apt update
sudo apt upgrade
sudo apt install git

# RHEL: update your distribution
sudo dnf update
sudo dnf install git

# Docker Engine install
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# ensure `docker` is running
sudo systemctl enable --now docker
sudo docker ps

# add yourself as to the `docker` admin
sudo usermod -aG docker $USER
logout
```

## Utility Containers

These utility containers are intended for operators who are setting up a host and need a few focused building blocks around editing, trust, certificates, networking, and DNS.

You do not need all of them.

| Container | Purpose |
|---|---|
| [`config-editor`](utils/README.md#config-editor) | Web UI to edit compose files, manage containers, and view logs — start here |
| [`ca-enroll`](utils/README.md#ca-enroll) | Assemble and distribute a CA root trust bundle |
| [`certsrv-ca`](utils/README.md#certsrv-ca) | Fetch CA certificates from Windows CERTSRV |
| [`cert-enroll`](utils/README.md#cert-enroll) | Handle certificate enrollment and renewal |
| [`certsrv-submit`](utils/README.md#certsrv-submit) | Auto-fulfill cert-enroll requests via Windows CERTSRV |
| [`dhcp-fw`](utils/README.md#dhcp-fw) | Obtain an ingress IP via DHCP; enforce port 80/443 firewall |
| [`ns-update`](utils/README.md#ns-update) | Keep DNS aligned with the DHCP-assigned address |
| [`egress-fw`](utils/README.md#egress-fw) | Restrict outbound TCP access |



## Simple Docker Compose File

The simplest production deployment: Caddy as the HTTPS ingress in front of VertiGIS Studio. The host machine's static IP/DNS is used directly — no separate ingress network interface is required.

Create a working directory (e.g. `~/stacks/studio`) with the following files:

```text
studio/
├── docker-compose.yml
├── Caddyfile
└── certs/            ← only needed for Manual TLS (see below)
    ├── server-crt.pem
    └── server-key.pem
```

**docker-compose.yml**
```yaml
services:
  caddy:
    image: caddy:2
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - caddy_data:/data
      - caddy_config:/config
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ./certs:/certs:ro
    restart: unless-stopped

  studio:
    image: ghcr.io/vertigis/studio/base:latest
    environment:
      # TODO: full public URL including /studio path
      FRONTEND_URL: https://apps.contoso.com
      # TODO: VertiGIS Account ID (from support)
      VERTIGIS_ACCOUNT_ID: account_id
      # TODO: ArcGIS Portal URL
      ARCGIS_PORTAL_URL: https://portal.contoso.com/portal
      # TODO: ArcGIS App ID (register app in Portal, set redirect URL to FRONTEND_URL)
      ARCGIS_APP_ID: app_id
      VERTIGIS_PURGE: 1
      VERTIGIS_WORKERS: 8
    volumes:
      - data:/data
      - logs:/var/log
      - stmp:/stmp
    restart: unless-stopped

volumes:
  caddy_data: {}
  caddy_config: {}
  data: {}
  logs: {}
  stmp: {}
```

Then choose a Caddyfile below based on how your certificates are provisioned.

### Caddyfile: Manual TLS

Use this when IT provides a certificate (`server-crt.pem` / `server-key.pem`) directly. Place the PEM files in the `certs/` directory and reference them in the Caddyfile. `auto_https` is disabled because Caddy will not attempt ACME when TLS is configured manually.

```caddy
apps.contoso.com {
    tls /certs/server-crt.pem /certs/server-key.pem

    handle {
        reverse_proxy http://studio:8080
    }
}
```

### Configuration notes

- **`FRONTEND_URL`**: The public HTTPS URL of this Studio deployment (e.g. `https://apps.contoso.com`). Studio uses this for OAuth redirects and internal link generation — wrong value breaks login.
- **`VERTIGIS_ACCOUNT_ID`**: Your VertiGIS license account ID. Obtain from VertiGIS support.
- **`ARCGIS_PORTAL_URL`**: Base URL to your ArcGIS Enterprise Portal, including the `/portal` context (e.g. `https://portal.contoso.com/portal`).
- **`ARCGIS_APP_ID`**: App ID from an ArcGIS application registered in your Portal. When registering, set the Redirect URL to the value of `FRONTEND_URL`.
- **`VERTIGIS_WORKERS`**: Number of parallel background jobs. Default `8` is suitable for most deployments; increase on high-core hosts.
- **`data` volume**: Persistent Studio application data. Do not delete — contains configuration, app definitions, and job state.
- **`logs` volume**: Container logs. Safe to clear if disk space is a concern.
- **`stmp` volume**: Temporary job staging area. Safe to clear between restarts if needed.


## Recommended Docker Compose File

Caddy with a dedicated macvlan network interface, internal CA trust distribution, and automatic certificate management via your organization's ACME server. Caddy gets its own IP and MAC address on the physical network — separate from the host — so no host port mapping is needed and traffic arrives directly at Caddy. The `ca-enroll` container assembles your organization's CA bundle and shares it with Caddy so that Caddy can reach and validate your internal ACME server.

Create a working directory (e.g. `~/stacks/studio`) with the following files:

```text
studio/
├── docker-compose.yml
├── Caddyfile
└── ca_bundle.pem    ← seed CA certificates from your PKI (PEM format)
```

**docker-compose.yml**
```yaml
services:
  ca-enroll:
    image: ghcr.io/gpickell/starter-kit/ca-enroll:latest
    environment:
      CHECK_URLS: >
        https://ca.contoso.com/ca-root.pem
    volumes:
      - ca_dist:/data
    configs:
      - source: ca_bundle
        target: /opt/ca_bundle.pem
    restart: unless-stopped

  caddy:
    image: caddy:2
    volumes:
      - caddy_data:/data
      - caddy_config:/config
      - ca_dist:/etc/ssl/certs:ro
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
    networks:
      ingress:
        ipv4_address: 10.10.0.50
        mac_address: "02:42:0a:0a:00:32"
      default: {}
    restart: unless-stopped

  studio:
    image: ghcr.io/vertigis/studio/base:latest
    environment:
      # TODO: full public URL including /studio path
      FRONTEND_URL: https://apps.contoso.com
      # TODO: VertiGIS Account ID (from support)
      VERTIGIS_ACCOUNT_ID: account_id
      # TODO: ArcGIS Portal URL
      ARCGIS_PORTAL_URL: https://portal.contoso.com/portal
      # TODO: ArcGIS App ID (register app in Portal, set redirect URL to FRONTEND_URL)
      ARCGIS_APP_ID: app_id
      VERTIGIS_PURGE: 1
      VERTIGIS_WORKERS: 8
    volumes:
      - data:/data
      - logs:/var/log
      - stmp:/stmp
      - ca_dist:/etc/ssl/certs:ro
    restart: unless-stopped

networks:
  ingress:
    driver: macvlan
    driver_opts:
      parent: eth0
    ipam:
      config:
        - subnet: 10.10.0.0/24
          gateway: 10.10.0.1
  default:
    driver: bridge

volumes:
  caddy_data: {}
  caddy_config: {}
  ca_dist: {}
  data: {}
  logs: {}
  stmp: {}

configs:
  ca_bundle:
    file: ca_bundle.pem
```

**Caddyfile**
```caddy
{
    acme_ca https://acme.contoso.com/acme/directory
}

apps.contoso.com {
    handle {
        reverse_proxy http://studio:8080
    }
}
```

### Configuration notes

- **`ipv4_address` / `mac_address`**: Assign a static IP and MAC that IT has reserved on the VLAN for this service. Use the MAC to get a consistent DHCP lease if you prefer DHCP over a static assignment.
- **`parent: eth0`**: Replace with the actual host interface name (`ip link` to find it). On Hyper-V, MAC address spoofing must be enabled on the VM network adapter.
- **`subnet` / `gateway`**: Match your VLAN. Caddy's IP must fall inside the subnet and the gateway must be the VLAN's default gateway.
- **`acme_ca`**: Replace with your organization's ACME directory URL. Caddy reads the system trust store, so once `ca-enroll` has populated `/etc/ssl/certs` the ACME server's certificate is automatically trusted.
- **`ca_bundle.pem`**: Seed PEM containing at least the root and any intermediate CA certificates for your PKI. Caddy will not be able to reach the ACME server until this is populated.
- **`FRONTEND_URL`**: The public HTTPS URL of this Studio deployment. Must exactly match the Redirect URL registered in ArcGIS Portal for `ARCGIS_APP_ID`.
- **`ARCGIS_APP_ID`**: Register an application in your Portal, set its Redirect URL to `FRONTEND_URL`, and paste the resulting App ID here.
- **`ca_dist:/etc/ssl/certs`** on Studio: Provides the internal CA bundle so Studio can validate HTTPS to ArcGIS Portal. Studio may restart once while `ca-enroll` initializes on first deploy.


## Advanced Docker Compose File

Full Active Directory enterprise setup: DHCP-managed ingress IP, Kerberos DNS updates, automatic CA trust distribution from Windows ADCS, automatic certificate enrollment via CERTSRV, and an egress firewall on Studio.

| Service | Role |
|---|---|
| `dhcp-fw` | Acquires a dedicated DHCP IP on the macvlan ingress and enforces a port 80/443 ingress firewall |
| `ns-update` | Registers the DHCP-assigned IP in AD DNS via Kerberos-authenticated nsupdate |
| `certsrv-ca` | Fetches the CA certificate chain from Windows ADCS and feeds it into the trust store |
| `ca-enroll` | Assembles and distributes the CA trust bundle to all containers that need it |
| `cert-enroll` | Generates a CSR, waits for the signed certificate, and tracks renewal |
| `certsrv-submit` | Monitors for pending CSRs from `cert-enroll` and submits them to ADCS |
| `caddy` | HTTPS ingress using the certificate issued by `cert-enroll` |
| `studio` | VertiGIS Studio |
| `egress-fw` | Restricts Studio's outbound TCP traffic to allowed CIDRs |

`caddy`, `ns-update` both use `network_mode: service:dhcp-fw` — they share `dhcp-fw`'s network namespace so they ride the same DHCP-assigned IP. Since `dhcp-fw` is on both the `ingress` macvlan and the `default` bridge, containers in its namespace can reach Studio on the default bridge.

Create a working directory (e.g. `~/stacks/studio`) with the following files:

```text
studio/
├── docker-compose.yml
├── Caddyfile
├── ca_bundle.pem      ← root CA cert from IT (PEM, seed trust — see notes)
└── kinit_secret       ← Kerberos secret for user authentication
```

**docker-compose.yml**
```yaml
services:
  dhcp-fw:
    image: ghcr.io/gpickell/starter-kit/dhcp-fw:latest
    environment:
      DHCP_HOSTNAME: my-studio.contoso.com
    volumes:
      - dhcp_data:/var/lib/dhcpcd
    networks:
      ingress:
        mac_address: "02:42:0a:0a:00:32"
      default: {}
    hostname: my-studio
    privileged: true
    restart: unless-stopped

  ns-update:
    image: ghcr.io/gpickell/starter-kit/ns-update:latest
    environment:
      DNS_HOST: my-studio.contoso.com
      DNS_SERVER: dc01.contoso.com
      KINIT_PRINCIPAL: svc-containers@CONTOSO.COM
      KINIT_SECRET_FILE: /opt/secret
    configs:
      - source: kinit_secret
        target: /opt/secret
    network_mode: service:dhcp-fw
    restart: unless-stopped

  certsrv-ca:
    image: ghcr.io/gpickell/starter-kit/certsrv-ca:latest
    environment:
      CERTSRV_URL: https://ca.contoso.com
      KINIT_PRINCIPAL: svc-containers@CONTOSO.COM
      KINIT_SECRET_FILE: /opt/secret
    volumes:
      - ca_dist:/etc/ssl/certs:ro
      - ca_root:/data
    configs:
      - source: kinit_secret
        target: /opt/secret
    restart: unless-stopped

  ca-enroll:
    image: ghcr.io/gpickell/starter-kit/ca-enroll:latest
    volumes:
      - ca_dist:/data
      - ca_root:/opt/root:ro
    configs:
      - source: ca_bundle
        target: /opt/ca_bundle.pem
    restart: unless-stopped

  cert-enroll:
    image: ghcr.io/gpickell/starter-kit/cert-enroll:latest
    environment:
      CERT_DIR: /data/server
      CERT_CA: studio-web
      CERT_SUBJECT: CN=my-studio.contoso.com
      CERT_SAN: my-studio.contoso.com
    volumes:
      - certs_data:/data
    restart: unless-stopped

  certsrv-submit:
    image: ghcr.io/gpickell/starter-kit/certsrv-submit:latest
    environment:
      CERTSRV_URL: https://ca.contoso.com
      CERTSRV_CA: studio-web
      KINIT_PRINCIPAL: svc-containers@CONTOSO.COM
      KINIT_SECRET_FILE: /opt/secret
    volumes:
      - ca_dist:/etc/ssl/certs:ro
      - certs_data:/data
    configs:
      - source: kinit_secret
        target: /opt/secret
    restart: unless-stopped

  caddy:
    image: caddy:2
    volumes:
      - caddy_data:/data
      - caddy_config:/config
      - ca_dist:/etc/ssl/certs:ro
      - certs_data:/certs:ro
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
    network_mode: service:dhcp-fw
    restart: unless-stopped

  studio:
    image: ghcr.io/vertigis/studio/base:latest
    environment:
      # TODO: full public URL including /studio path
      FRONTEND_URL: https://my-studio.contoso.com
      # TODO: VertiGIS Account ID (from support)
      VERTIGIS_ACCOUNT_ID: account_id
      # TODO: ArcGIS Portal URL
      ARCGIS_PORTAL_URL: https://portal.contoso.com/portal
      # TODO: ArcGIS App ID (register app in Portal, set redirect URL to FRONTEND_URL)
      ARCGIS_APP_ID: app_id
      VERTIGIS_PURGE: 1
      VERTIGIS_WORKERS: 8
    volumes:
      - data:/data
      - logs:/var/log
      - stmp:/stmp
      - ca_dist:/etc/ssl/certs:ro
    restart: unless-stopped

  egress-fw:
    image: ghcr.io/gpickell/starter-kit/egress-fw:latest
    environment:
      ALLOW_CIDRS: >
        10.0.0.0/8
        172.16.0.0/12
        192.168.0.0/16
    network_mode: service:studio
    privileged: true
    restart: unless-stopped

networks:
  ingress:
    driver: macvlan
    driver_opts:
      parent: eth0
    ipam:
      config:
        - subnet: 10.10.0.0/24
          gateway: 10.10.0.1
  default:
    driver: bridge

volumes:
  dhcp_data: {}
  caddy_data: {}
  caddy_config: {}
  ca_dist: {}
  ca_root: {}
  certs_data: {}
  data: {}
  logs: {}
  stmp: {}

configs:
  ca_bundle:
    file: ca_bundle.pem
  kinit_secret:
    file: kinit_secret
```

**Caddyfile**
```caddy
my-studio.contoso.com {
    tls /certs/server/cert/fullchain.pem /certs/server/cert/privkey.pem

    handle {
        reverse_proxy http://studio:8080
    }
}
```

### Configuration notes

- **`mac_address`**: Assign a MAC that is stable and, if your DHCP server is configured to do so, maps to a reserved IP. On Hyper-V, MAC address spoofing must be enabled on the VM network adapter (`Set-VMNetworkAdapter -MacAddressSpoofing On`).
- **`parent: eth0`**: Replace with the actual host NIC name (`ip link` to find it). Must be the interface on the VLAN that Studio's IP will live on.
- **`subnet` / `gateway`**: Match your VLAN. If IT assigns Caddy a static IP via DHCP reservation the gateway must be correct or `dhcp-fw` will lose the lease.
- **`ca_bundle.pem`**: Seed PEM needed to bootstrap trust before `certsrv-ca` can run. Download the root CA from ADCS at `https://ca.contoso.com/certsrv/certcarc.asp` (no authentication required) or ask IT for the root PEM. Once `certsrv-ca` is running it fetches the full chain and `ca-enroll` keeps the bundle current.
- **`kinit_secret`**: The account that can access AD CERTSRV and DNS.
- **`CERT_CA` / `CERTSRV_CA`**: Must be identical (`studio-web` above). Use a unique label per service so `certsrv-submit` routes requests to the right CA.
- **`ALLOW_CIDRS`**: Tighten to the actual ranges Studio must reach — GIS tile services, license servers, LDAP/AD, SMTP, etc. `10.0.0.0/8` is a reasonable starting point for a private network; remove the RFC-1918 ranges that don't apply to your environment.
- **First-time startup**: `cert-enroll` must complete enrollment before Caddy can serve HTTPS. Caddy will restart once or twice on first deploy while it waits for the certificate. The cert is persisted in `certs_data` so all subsequent restarts are immediate.
- **`FRONTEND_URL`**: The public HTTPS URL of this Studio deployment (e.g. `https://my-studio.contoso.com`). Must exactly match the Redirect URL registered in ArcGIS Portal for `ARCGIS_APP_ID`.
- **`ARCGIS_APP_ID`**: Register an application in your Portal, set its Redirect URL to `FRONTEND_URL`, and paste the resulting App ID here.
- **`ca_dist:/etc/ssl/certs`** on Studio: Ensures Studio trusts the internal CA when connecting to ArcGIS Portal. Since `egress-fw` restricts Studio's outbound TCP, make sure `ALLOW_CIDRS` includes the Portal host's IP range.
