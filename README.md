# coreos
Installation script for CoreOS on Gandi server with gandi.cli

## original idea
"fork" from jmbarbier idea : 
https://gist.github.com/jmbarbier/ab06cf23735845a0167a

## requirements
 - gandi.cli
 - credits on iaas account

## howto 

### version 1 :  install-core.sh:

Download on local computer and make it executable : 

    $ wget https://raw.githubusercontent.com/azediv/gnadi-coreos/master/install-core.sh && chmod +x install-core.sh

Edit install-core.sh to change hostname, disk name, user and personalize cloud-config.yml configuration parameters
(etcd2, fleet, etc)

hostname must be short for now, 7 or 8 max due to the use of sys_$VM, disk name cannot be too long

Then run :

    $ ./install-core.sh


### version 2 :  core-config.sh and cloud-config.sh :

Download on local computer and make it executable

    $ wget https://raw.githubusercontent.com/azediv/gnadi-coreos/master/core-config.sh && chmod +x core-config.sh

Edit core-config.sh to change hostname, disk name, user 
hostname must be short for now, 7 or 8 max
Then run :

    $ ./core-config.sh

## files

### install-core.sh

install-core.sh is used locally with gandi.cli to create vm and install coreos with /gandi/config json file 
json config is download and used to create cloud-config.yml
cloud-config.yml is scp to temp vm before install
details in script... (more soon)

### core-config.sh

core-config is used locally with gandi.cli to create vm and install coreos with /gandi/config json file 
details in script... (more soon)

### cloud-config.sh

cloud-config is used to create cloud-config.yml with /gandi/config file
script is used to get from gandi json file :

 * username
 * sshkey
 * hashed password
 * network config : ip / route / dns
 * more ?

TODO : during script propose to edit cloud-config.yml to add discovery token, units, etc...

cloud-config.yml is then used to configure coreos installation