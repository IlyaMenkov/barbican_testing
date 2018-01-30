#!/usr/bin/env bash

# Install DogTag formula
apt-get install salt-formula-dogtag

# Create symlink
ln -s /usr/share/salt-formulas/reclass/service/dogtag /srv/salt/reclass/classes/service/dogtag

# Create /srv/salt/reclass/classes/cluster/virtual-mcp11-aio/openstack/dogtag.yml
cp dogtag.yml /srv/salt/reclass/classes/cluster/virtual-mcp11-aio/openstack/

init_file='/srv/salt/reclass/classes/cluster/virtual-mcp11-aio/openstack/init.yml'

# Apply some changes
sed -i 's/service.barbican.server.plugin.simple_crypto/service.barbican.server.plugin.dogtag/g' $init_file
sed -i '/service.barbican.server.plugin.dogtag/a - cluster.virtual-mcp11-aio.openstack.dogtag' $init_file
sed -i '/crypto_plugin: simple_crypto/d' $init_file
sed -i 's/store_plugin: store_crypto/store_plugin: dogtag_crypto/g' $init_file
sed -i 's/barbican_integration_enabled: False/barbican_integration_enabled: True/g' $init_file

# Check if Reclass render is fine
reclass-salt --top

# Refresh Salt pillars
salt '*' saltutil.pillar_refresh

# Apply DogTag state
salt '*' state.apply dogtag.server

# Re-apply some states
salt -C 'I@barbican:server and *01*' state.apply barbican.server
salt -C 'I@barbican:server' state.apply barbican.server
salt -C 'I@glance:server and *01*' state.apply glance.server
salt -C 'I@glance:server' state.apply glance.server
salt -C 'I@cinder:controller and *01*' state.apply cinder
salt -C 'I@cinder:controller' state.apply cinder
salt -C 'I@nova:controller and *01*' state.apply nova.controller
salt -C 'I@nova:compute' service.restart nova-compute

# Check If Barbican works properly
openstack secret store --name mysecret --payload j4=]d21

source /root/keystonercv3

# Create network
network_id=`openstack network create $1"_net" | grep " id"| awk {'print $4'}`
openstack subnet create --network $1"_net" --subnet-range 192.168.1.0/24 $1"_subnet"