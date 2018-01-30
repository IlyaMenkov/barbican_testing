#!/usr/bin/env bash

source /root/keystonercv3

# Create image
wget http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img
glance image-create --name $1 --visibility public --disk-format qcow2 \
  --container-format bare --file cirros-0.3.5-x86_64-disk.img --progress

# Create flavor
openstack flavor create $1 --ram 512 --disk 1 --vcpus 1

# Boot instance
nova boot --flavor $1 --image $1 --nic net-id=$1 $1

# Check that instance in ERROR state
check_error_state=`nova list | awk '/test/ && /ERROR/'`
check_error_log=`grep -irn "SignatureVerificationError: Signature verification for the image failed:" \
/var/log/nova/nova-compute.log`

if [[ -z "$check_error_state" || -z "$check_error_log" ]]
then
  echo "Test FAILED"
else
  echo "Test PASSED"
fi
