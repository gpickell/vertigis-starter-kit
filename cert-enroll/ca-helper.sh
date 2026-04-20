#!/bin/bash

die_unconfigured() {
    exit 4
}

die_rejected() {
    exit 2
}

die_unreachable() {
    exit 3
}

issued() {
    envsubst < /success.md > /tmp/success.md
    curl -sS "https://ntfy.sh/$CERTMONGER_CA_NICKNAME" \
        -H "Markdown: yes" \
        -H "Priority: high" \
        -T /tmp/success.md > /dev/null 2> /dev/null

    rm -rf "$DIR"
    exit 0
}

wait_more() {
    echo 15
    echo $CERTMONGER_CA_COOKIE
    exit 5
}

submit() {
    export CERTMONGER_CA_COOKIE="request-$(pwgen 32 1)"
    export DIR="/data/$CERTMONGER_CA_COOKIE"
    mkdir -p "$DIR"
    echo "$CERTMONGER_CSR" > "$DIR/csr.pem"
    env > "/tmp/env-submit"

    envsubst < /renew.md > /tmp/renew.md
    curl -sS "https://ntfy.sh/$CERTMONGER_CA_NICKNAME" \
        -H "Markdown: yes" \
        -H "Priority: high" \
        -T /tmp/renew.md > /dev/null 2> /dev/null

    wait_more
}

poll() {
    export DIR="/data/$CERTMONGER_CA_COOKIE"
    env > "/tmp/env-poll"

    if [ ! -d "$DIR" ]; then
        die_rejected
    fi

    curl -fsSL "https://ntfy.sh/$CERTMONGER_CA_COOKIE/json?poll=1" > /tmp/reply.json 2> /dev/null
    jq -r .attachment.url /tmp/reply.json > /tmp/attachment.url 2> /dev/null

    url=$(cat /tmp/attachment.url)
    url=${url#null}

    if [ -n "$url" ]; then
        curl -fsSL "$url" > /tmp/cert.pem 2> /dev/null
    fi
    
    file=/tmp/cert.pem
    [ -f "$DIR/cert.pem" ] && file="$DIR/cert.pem"
    
    if openssl pkcs7 -in "$file" -out "$DIR/fullchain.pem" -print_certs 2> /dev/null; then
        cp "$DIR/fullchain.pem" /tmp/result/fullchain.pem
        cat "$file"
        issued
    fi

    if openssl x509 -in "$file" -noout 2> /dev/null; then
        cp "$file" /tmp/result/fullchain.pem
        cat "$file"
        issued
    fi

    wait_more
}

if [ "$CERTMONGER_OPERATION" = "SUBMIT" ]; then
    submit
fi

if [ "$CERTMONGER_OPERATION" = "POLL" ]; then
    poll
fi

die_unconfigured
