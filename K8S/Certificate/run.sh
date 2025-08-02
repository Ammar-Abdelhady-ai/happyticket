kubectl create secret tls happyticket-tls \
  --cert=./cert.pem \
  --key=./private.pem \
  -n happyticket