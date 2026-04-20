# Utility Containers

## config-editor
Useful when you want to manage your container stacks using a browser:
- Edit compose files and configuration.
- Inspect and manage containers as well as files.
- Browse example content from this repository.
- Manage the host Docker Engine from a browser session
- View logs pertaining to containers.

### Compose Example
```yaml
services:
  editor:
    image: ghcr.io/gpickell/starter-kit/config-editor:latest
    ports:
      - 127.0.0.1:8080:8080
    volumes:
      - /opt/stacks:/opt/stacks
      - /var/run/docker.sock:/var/run/docker.sock
      - home:/root
    restart: unless-stopped

volumes:
  home: {}
```

### Usage
```sh
# initial setup
sudo mkdir -p /opt/stacks
mkdir -p vertigis-starter-kit
git clone --depth 1 https://github.com/gpickell/vertigis-starter-kit .

# set the password
docker compose run --rm editor

# start
docker compose up -d

# update: pull repo and images
git pull
docker compose pull
docker compose up -d
```

### Links
- [Launch Editor](https://localhost:8080/)


## ca-enroll
Useful when you need to assemble and distribute a CA root trust bundle:
- Consume CA trust anchors using Cert/PEM files.
- Consume CA trust anchors using Cert/PEM distribution points.
- Offers coherent CA trust material for other containers.

### Compose Example
```yaml
services:
  ca-enroll:
    image: ghcr.io/gpickell/starter-kit/ca-enroll:latest
    environment:
      # additional distribution lists to check
      CHECK_URLS: >
        https://pki.example.local/roots.pem
        https://pki.example.local/extra-roots.pem
    volumes:
      - certs_ca:/data
    configs:
      # initial distribution liss
      - source: ca_bundle
        target: /opt/ca_bundle
    restart: unless-stopped

volumes:
  certs_ca: {}

configs:
  ca_bundle:
    content: |
      -----BEGIN CERTIFICATE-----
      ...
      -----END CERTIFICATE-----
```

### Usage
```sh
# start
docker compose up -d

# update
docker compose pull
docker compose up -d
```

## `cert-enroll`
Useful when you want to partially automate certificate enrollment:
- Can be useful if you can't use ACME.
- Can monitor and notify you when you need to take action.

### Compose Example
```yaml
services:
  cert-enroll:
    image: ghcr.io/gpickell/starter-kit/cert-enroll:latest
    environment:
      # which folder to manage
      CERT_DIR: /data/server
      # ca/topic to notify via ntfy.sh
      CERT_CA: web-server-sd87g8h7ds8sdt8h
      # the subject for the csr/cert
      CERT_SUBJECT: CN=server.example.local
      # the DNS names for the csr/cert
      CERT_SAN: studio.contoso.com studio-prod.local
    volumes:
      - certs_data:/data
    restart: unless-stopped

volumes:
  certs_data: {}
```

### Usage
```sh
# start
docker compose up -d

# update
docker compose pull
docker compose up -d
```

### Operational guidance
This container uses `ntfy` as the handoff point between the running container and the human who fulfills the certificate request.

Typical Flow:
1. Start the container with a persistent certificate directory.
2. The container generates or refreshes the request.
3. Notifications are published to an ntfy topic.
4. Some operator subscribes to that topic and receives the request details.
5. Some operator completes the organization’s normal certificate issuance process.
6. Some operator replies with the resulting certificate chain.
7. The container picks it up and concludes the renewal/submission process.

### About `ntfy`
`ntfy` is a lightweight publish/subscribe notification system that works over simple HTTP requests. A user can subscribe through the ntfy web UI, mobile app, or other supported clients, which makes it convenient for lightweight human-assisted operational flows.


## dhcp-fw
Useful when you want to manage your own IP assignment:
- If testing, bypass IT requirements.
- If production, IT may want to manage IP assignments using DHCP controls.

### Compose Example
```yaml
services:
  dhcp-fw:
    image: ghcr.io/gpickell/starter-kit/dhcp-fw:latest
    environment:
      # the hostname to send via DHCP
      DHCP_HOSTNAME: my-studio.contoso.com
    volumes:
      - dhcp_data:/var/lib/dhcpcd
    networks:
      - ingress
      - default
    hostname: my-studio
    privileged: true
    restart: unless-stopped    

networks:
  default: {}
  ingress: 
    driver: macvlan
    driver_opts:
      parent: eth0

volumes:
  dhcp_data: {}
```

### Usage
```sh
# start
docker compose up -d

# update
docker compose pull
docker compose up -d
```


## ns-update
Useful when you want to manage your own IP assignment and update DNS appropriately.

### Compose Example
```yaml
services:
  ns-update:
    image: ghcr.io/gpickell/starter-kit/ns-update:latest
    environment:
      # the host entry to update
      DNS_HOST: my-studio.contoso.com
      # the server that should perform the update
      DNS_SERVER: dc01.contoso.com
      # update using kerberos authentication
      NSUPDATE_KINIT: --password-file=/opt/secret user@CONTOSO.COM
      # update using key authentication
      NSUPDATE_KEY: keyspec
      # update using shared secret authentication
      NSUPDATE_SECRET: /opt/secret
    configs:
      - source: nsupdate_secret
        target: /opt/secret
    network_mode: service:dhcp-fw
    restart: unless-stopped

configs:
  nsupdate_secret:
    file: nsupdate_secret
```

### Usage
```sh
# start
docker compose up -d

# update
docker compose pull
docker compose up -d
```


## egress-fw
Useful when you want to restrict outgoing requests:
- Applies network level policy controls on a container.
- Only allow access to specific systems.

### Compose Example
```yaml
services:
  egress-fw:
    image: ghcr.io/gpickell/starter-kit/egress-fw:latest
    environment:
      ALLOW_CIDRS: >
        10.0.0.0/8
        192.168.100.0/24
    # manage the outgoing network traffic for the app container
    network_mode: service:my-app
    privileged: true
    restart: unless-stopped
```

### Usage
```sh
# start
docker compose up -d

# update
docker compose pull
docker compose up -d
```
