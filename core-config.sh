#!/bin/bash

# core-install script with /gandi/config file
# howto import json data and create cloud-config.yml

# Define vm hostname

VM=coreos

# Define username

USER=coruser

# Define Datacenter

DC=US

# Define SSHKEY

# SSHKEY=~/.ssh/id_rsa.pub

# Create VM Debian (min 512Mo, 256Mo is not enough to install packages)

gandi vm create --datacenter $DC --memory 512 --cores 1 --ip-version 4  --hostname $VM --image 'Debian 8 64 bits (HVM)' --login $USER --password

wait

# disk creation and attach to vm as coreos-install.sh target 

gandi disk create --name core_sys --size 10G --datacenter $DC --vm $VM

wait

# Connexion SSH to Debian vm
# Detach coreos disk before installation :
# Get coreos-install script
# Get interface configuration script for cloud-config

gandi vm ssh $VM "umount /dev/sdc;\

apt-get update && apt-get install -y wget &&\

wget https://raw.github.com/coreos/init/master/bin/coreos-install &&\

wget https://raw.githubusercontent.com/azediv/gnadi-coreos/master/cloud-config.sh &&\

chmod +x cloud-config.sh &&\

chmod +x coreos-install &&\

./cloud-config.sh &&\

./coreos-install -d /dev/sdc -C alpha -c cloud-config.yml &&\

exit"

wait

gandi vm stop $VM

wait

gandi disk detach sys_coreos

wait

gandi disk detach core_sys

wait

gandi disk update --kernel raw core_sys

wait

gandi vm start $VM

wait

IP=`gandi vm info $VM | grep ip4 | sed 's/ip4 *: //g'`

ssh-keygen -f "~/.ssh/known_hosts" -R $IP

gandi vm ssh --login $USER $VM



