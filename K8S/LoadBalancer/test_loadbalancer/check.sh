while true; do
  curl -k -s -H "Host: test.ticketshappy.com" https://142.132.210.239/whoami | grep -i hostname
  sleep 1
done
