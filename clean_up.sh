#!/usr/bin/env bash

# Clean Up
openstack flavor delete $1
openstack image delete $1
openstack server delete $1
openstack network delete $1'_net'
rm cirros-0.3.5-x86_64-disk.img