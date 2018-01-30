#!/usr/bin/env bash

# Clean Up
openstack flavor delete $1
openstack image delete $1
openstack server delete $1
openstack network delete $1'_net'
rm $1.img