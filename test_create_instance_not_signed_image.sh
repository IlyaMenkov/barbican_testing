#!/usr/bin/env bash

source keystonercv3

# Install DogTag formula
apt-get install salt-formula-dogtag

# Create symlink
ln -s /usr/share/salt-formulas/reclass/service/dogtag /srv/salt/reclass/classes/service/dogtag

# Create /srv/salt/reclass/classes/cluster/virtual-mcp11-aio/openstack/dogtag.yml
cp dogtag.yaml /srv/salt/reclass/classes/cluster/virtual-mcp11-aio/openstack/

init_file='/srv/salt/reclass/classes/cluster/virtual-mcp11-aio/openstack/init.yml'

# Apply some changes
sed -i 's/-service.barbican.server.plugin.simple_crypto/- service.barbican.server.plugin.dogtag/g' $init_file
sed -i '/- service.barbican.server.plugin.dogtag/a - cluster.virtual-mcp11-aio.openstack.dogtag' $init_file
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
echo $?

# If private network doesn't exist create one
network_id=`openstack network list | awk '/private/ || /internal/' |awk {'print $2'} | head -1`

if [ -z  $network_id ]
then
  network_id=`openstack network create internal_net | grep " id"| awk {'print $4'}`
  openstack subnet create --network internal_net --subnet-range 192.168.1.0/24 internal_subnet
  openstack router create test_barbican_r1
  openstack router add port test_barbican_r1 internal_subnet
fi

wget http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img
glance image-create --name test_barbican --visibility public --disk-format qcow2 \
  --container-format bare --file cirros-0.3.5-x86_64-disk.img --progress

# Boot instance
nova boot --flavor m1.extra_tiny --image test_barbican --nic net-id=d23f9845-cbce-47a6-be15-0603f6a31365 test_barbican

# Check that instance in ERROR state
check_error_state=`nova list | awk '/test/ && /ERROR/'`
if [ -z  check_error_state ]
then
  echo "Instance was created, Test FAILED"
else
  echo "Instance in ERROR state as expected, Test PASSED"
fi