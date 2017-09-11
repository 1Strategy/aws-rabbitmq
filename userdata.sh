#!/usr/bin/env bash
set -o errexit

apt-get -y update
apt-get -y upgrade 


# Create volume for Rabbit messages and queues
pvcreate /dev/xvdf
vgcreate vg0 /dev/xvdf
lvcreate -l 100%FREE -n rabbitmq vg0
mkfs.ext4 /dev/vg0/rabbitmq
mkdir /var/lib/rabbitmq/
echo "/dev/mapper/vg0-rabbitmq /var/lib/rabbitmq ext4 defaults 0 2" >> /etc/fstab
mount -a