#!/bin/bash

IP=`cat /gandi/config | grep -Po '(?<="pna_address": ")[^"]*' | head -1`

ROUTE=`cat /gandi/config | grep -Po '(?<="pbn_gateway": ")[^"]*' | head -1`

DNS=`cat /etc/resolv.conf | awk '{ print $2}' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -1`

PASS=`cat /gandi/config | grep -Po '(?<="password": ")[^"]*'`

USER=`cat /gandi/config | grep -Po '(?<="user": ")[^"]*'`

SSH=`cat /gandi/config | grep -Po '(?<="ssh_key": ")[^"]*'`

HOSTNAME=`cat /gandi/config | grep -Po '(?<="vm_hostname": ")[^"]*'`

printf "#cloud-config
coreos:
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
hostname: $HOSTNAME
users:
  - name: $USER
    passwd: $PASS
    groups:
      - sudo

    ssh_authorized_keys:
      - $SSH" > cloud-config.yml

exit
