#!/usr/bin/env bash
set -o errexit
set -o nounset

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

rabbitmqctl stop-app

# Use FQDNs for RabbitMQ clustering
echo "USE_LONGNAME=true" >> /etc/rabbitmq/rabbitmq-env.conf

# Set Erlang cookie for RabbitMQ clustering
echo "EHLKUCICVURANTZUDLJG" > /var/lib/rabbitmq/.erlang.cookie
chmod 0400 /var/lib/rabbitmq/.erlang.cookie
chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
rabbitmqctl start_app

# Reboot if kernel updates require it
[[ -f "/var/run/reboot-required" ]] && shutdown -r now