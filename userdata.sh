#!/usr/bin/env bash

# Copyright 2017 Zulily, LLC
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.


set -o errexit
set -o nounset
set -o pipefail

readonly ERLANG_COOKIE="EHLKUCICVURANTZUDLJG"


# Create volume for Rabbit messages and queues
create_rabbit_volume() {
    pvcreate /dev/xvdf
    vgcreate vg0 /dev/xvdf
    lvcreate -l 100%FREE -n rabbitmq vg0
    mkfs.ext4 /dev/vg0/rabbitmq
    mkdir /var/lib/rabbitmq/
    echo "/dev/mapper/vg0-rabbitmq /var/lib/rabbitmq ext4 defaults 0 2" >> /etc/fstab
    mount -a
}

# Add RabbitMQ repo to apt sources
add_rabbit_pkg_source() {
    cat <<EOF > /etc/apt/sources.list.d/rabbitmq.list
deb http://www.rabbitmq.com/debian/ testing main
EOF
}

add_rabbit_gpg_key() {
    curl https://www.rabbitmq.com/rabbitmq-release-signing-key.asc -o /tmp/rabbitmq-release-signing-key.asc
    apt-key add /tmp/rabbitmq-release-signing-key.asc
    rm /tmp/rabbitmq-release-signing-key.asc
}

apt_get_upgrade() {
    apt-get -qq update
    DEBIAN_FRONTEND=noninteractive apt-get -qq -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" dist-upgrade
}

install_rabbitmq() {
    apt-get -qq install rabbitmq-server
    systemctl enable rabbitmq-server
}

add_rabbit_mgmt_plugin() {
    rabbitmq-plugins enable rabbitmq_management
}

modify_nofile_limit() {
    cd /etc/systemd/system
    mkdir rabbitmq-server.service.d 
cat >> /etc/systemd/system/rabbitmq-server.service.d/limits.conf <<EOL 
[Service]
LimitNOFILE=10000
EOL
    systemctl daemon-reload
}

# Set Erlang cookie for RabbitMQ clustering
set_erlang_cookie() {

    echo "${ERLANG_COOKIE}" > /var/lib/rabbitmq/.erlang.cookie
    chmod 0400 /var/lib/rabbitmq/.erlang.cookie
    chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
}

download_autocluster_plugin() {
    cd /usr/lib/rabbitmq/lib/rabbitmq_server-3.6.12/plugins
    wget https://github.com/rabbitmq/rabbitmq-autocluster/releases/download/0.8.0/autocluster-0.8.0.ez
    wget https://github.com/rabbitmq/rabbitmq-autocluster/releases/download/0.8.0/rabbitmq_aws-0.8.0.ez
}

enable_autocluster_plugin() {
    rabbitmq-plugins enable autocluster --offline
}

configure_autocluster_plugin() {
    EC2_AVAIL_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
    EC2_REGION="$(echo ${EC2_AVAIL_ZONE} | sed 's/[a-z]$//')" 
    
    
 cat >> /etc/rabbitmq/rabbitmq.config <<EOL
[
  {rabbit, [{vm_memory_high_watermark, 0.5},
  {disk_free_limit, {mem_relative, 1.5}}
  ]},
  {autocluster, [
    {autocluster_log_level, debug},
    {backend, aws},
    {aws_autoscaling, true},
    {aws_ec2_region, "${EC2_REGION}"}
  ]}
]. 
EOL
}


reboot_if_required() {
    if [[ -f "/var/run/reboot-required" ]]; then
        reboot
    fi
}



main() {
    create_rabbit_volume
    add_rabbit_pkg_source
    add_rabbit_gpg_key
    apt_get_upgrade
    install_rabbitmq
    add_rabbit_mgmt_plugin
    modify_nofile_limit
    rabbitmqctl stop
    set_erlang_cookie
    download_autocluster_plugin
    enable_autocluster_plugin
    configure_autocluster_plugin

    reboot_if_required

    # RabbitMQ will start on boot
    systemctl start rabbitmq-server
}

main "$@"