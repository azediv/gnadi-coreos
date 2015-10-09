#!/bin/bash

# core-install script with /gandi/config file
# howto import json data and create cloud-config.yml

# Define vm hostname

VM=coreos

# Define Datacenter

DC=US

# Create VM Debian (min 512Mo, 256Mo is not enough to install packages)

gandi vm create --datacenter $DC --memory 512 --cores 1 --ip-version 4  --hostname $VM --image 'Debian 8 64 bits (HVM)'

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

wget https://raw.githubusercontent.com/azediv/gnadi-coreos/master/if-core-config.sh &&\

chmod +x if-core-config.sh &&\

chmod +x coreos-install"

# here come the fun part :)

