#!/bin/bash

# get ip address

IP=`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`

# get route

ROUTE=`route | awk '{ print $2}' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`

# get dns

DNS=`cat /etc/resolv.conf | awk '{ print $2}' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -1`

printf '\nNetwork Interface Configuration\n\n'

echo IP = $IP

echo ROUTE = $ROUTE

echo DNS = $DNS

printf '\nCoreOS cloud-config.yml file\n\n'

# Create cloud-config.yml Coreos Install File

cat > cloud-config.yml << EOF
#cloud-config
coreos
  units:
    - name: systemd-networkd.service
      command: stop
    - name: 00-eth0.network
      runtime: true
      content: |
        [Match]
        Name=eth0

        [Network]
        DNS=$DNS
        Address=$IP
        Gateway=$ROUTE
    - name: systemd-networkd.service
      command: start

EOF

cat cloud-config.yml

exit

