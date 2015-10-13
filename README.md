# coreos
Installation script for CoreOS on Gandi server with gandi.cli

## original idea
"fork" from jmbarbier idea to create a cluster of coreos on Gandi vm : 
https://gist.github.com/jmbarbier/ab06cf23735845a0167a


## requirements
 - gandi.cli
 - credits on iaas account

## howto 

Download on local computer and make it executable : 

    $ wget https://raw.githubusercontent.com/azediv/gnadi-coreos/master/install-core.sh && chmod +x install-core.sh

Edit install-core.sh to change hostname, disk name, user and personalize cloud-config.yml configuration parameters
(etcd2, fleet, etc)

hostname must be short for now, 7 or 8 max due to the use of sys_$VM, disk name cannot be too long

Then run :

    $ ./install-core.sh

## files

### install-core.sh

install-core.sh is used locally with gandi.cli to create vm and install coreos with /gandi/config json file

json config is download and used to create cloud-config.yml

cloud-config.yml is scp to temp vm before install

details in script... (more soon)
