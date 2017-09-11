#!/usr/bin/env bash
set -o errexit


# Create volume for Rabbit messages and queues
pvcreate /dev/xvdf
vgcreate vg0 /dev/xvdf
lvcreate -l 100%FREE -n rabbitmq vg0
mkfs.ext4 /dev/vg0/rabbitmq
mkdir /var/lib/rabbitmq/
echo "/dev/mapper/vg0-rabbitmq /var/lib/rabbitmq ext4 defaults 0 2" >> /etc/fstab
mount -a


cat <<EOF > /etc/apt/sources.list.d/rabbitmq.list
deb http://www.rabbitmq.com/debian/ testing main
EOF

curl https://www.rabbitmq.com/rabbitmq-release-signing-key.asc -o /tmp/rabbitmq-release-signing-key.asc
apt-key add /tmp/rabbitmq-release-signing-key.asc
rm /tmp/rabbitmq-release-signing-key.asc

apt-get -qy update
apt-get -y dist-upgrade 
apt-get -qy install rabbitmq-server


rabbitmq-plugins enable rabbitmq_management
