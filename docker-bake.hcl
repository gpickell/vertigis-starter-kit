variable "OWNER" {
    default = "gpickell"
}

variable "REPO" {
    default = "starter-kit"
}

variable "REF_NAME" {
    default = "custom"
}

variable "RUN_NUMBER" {
    default = "0"
}

target "image" {
    matrix = {
        item = [
            "config-editor",
            "container-fw-egress",
            "dhcp-fw-ingress",
            "scep-enrollment",
        ]
    }

    name       = item
    context    = item

    tags = [
        "ghcr.io/${OWNER}/${REPO}/${item}:${REF_NAME}.${RUN_NUMBER}",
        "ghcr.io/${OWNER}/${REPO}/${item}:${REF_NAME}",
        "ghcr.io/${OWNER}/${REPO}/${item}:latest",
    ]
}

group "default" {
  targets = ["image"]
}
