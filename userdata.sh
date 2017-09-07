#!/usr/bin/env bash
set -o errexit

apt-get -y update

# Create volume for Rabbit messages and queues
pvcreate /dev/xvdf
vgcreate vg0 /dev/xvdf
lvcreate -l 100%FREE -n myapp vg0
mkfs.ext4 /dev/vg0/myapp
mkdir /var/lib/rabbitmq/
echo "/dev/mapper/vg0-myapp /var/lib/rabbitmq ext4 defaults 0 2" >> /etc/fstab
mount -a