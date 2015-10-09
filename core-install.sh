#!/bin/bash

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

# Define vm IP address to scp base config file

IP=`gandi vm info $VM | grep ip4 | sed 's/ip4 *: //g'`

# Add ssh key to cloud-config

printf "ssh_authorized_keys:\n - " > base_cloud_config.yml

cat ~/.ssh/id_rsa.pub >> base_cloud_config.yml

# Upload cloud-config

scp base_cloud_config.yml root@$IP:/root/base-cloud-config.yml

# SSH to vm 

gandi vm ssh $VM "./if-core-config.sh &&\

cat base-cloud-config.yml >> cloud-config.yml &&\

"
# NOT FINISH !!!
# TODO : Create cloud-config from /gandi/config 