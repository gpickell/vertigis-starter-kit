## Certificate Renewal Request

A certificate renewal is needed: $CERTMONGER_CA_COOKIE

### CA
```
$CERTMONGER_CA_NICKNAME
```

### Subject
```
$CERTMONGER_REQ_SUBJECT
```

### Subject Alternative Names
```
$CERTMONGER_REQ_HOSTNAME
```

### Certificate Request
```
$CERTMONGER_CSR
```

### Reply
```
curl https://ntfy.sh/$CERTMONGER_CA_COOKIE -H "Filename: fullchain.pem" -T fullchain.pem
```
