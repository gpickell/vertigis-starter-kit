#!/bin/bash
set -e

cat > /etc/certmonger/certmonger.conf <<EOF
[scep]
challenge_password_otp = yes
EOF

rm -rf /tmp/* /run/dbus/*
[ -f /data/certmonger/.otp ] && otp=$(cat /data/certmonger/.otp)
[ "$otp" != "$SCEP_OTP" ] && rm -rf /data/certmonger

echo -n "$SCEP_DIR" > /tmp/.dir
echo -n "$SCEP_URL" > /tmp/.url
mkdir -p /data /run/dbus /data/certmonger "$SCEP_DIR"

/app/init.ts
update-ca-certificates
dbus-daemon --system --fork --nopidfile
certmonger -f -S

if [ ! -f /data/certmonger/.otp ]; then
    echo "Seeding Certmonger with SCEP credentials"
    name="CN=${SCEP_SAN%% *}"

    args=()
    for san in $SCEP_SAN; do
        args+=(-D "$san")
    done

    echo NAME: "$name"
    echo SANS: "${args[@]}"

    getcert add-scep-ca \
        -c scep \
        -u "$SCEP_URL" \
        -R /etc/ssl/certs/ca-certificates.crt || true

    getcert request \
        -c scep \
        -f "$SCEP_DIR/cert.pem" \
        -k "$SCEP_DIR/privkey.pem" \
        -N "$name" "${args[@]}" \
        -u digitalSignature \
        -u keyEncipherment \
        -U id-kp-serverAuth \
        -L "$SCEP_OTP" \
        -C /update.sh \
        -w || true

    echo -n "$SCEP_OTP" > /data/certmonger/.otp
fi

"$@" &

trap exit TERM INT
wait
