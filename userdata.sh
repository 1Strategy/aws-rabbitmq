#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

readonly ERLANG_COOKIE="EHLKUCICVURANTZUDLJG"

# set hostname fqdn
set_fqdn() {
    local ip_address=`hostname -I`
    local hostname=`hostname`
    local fqdn=`curl -s http://169.254.169.254/latest/meta-data/hostname`

    echo "${ip_address} ${fqdn} ${hostname}" >> /etc/hosts
}

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
}

add_rabbit_mgmt_plugin() {
    rabbitmq-plugins enable rabbitmq_management
}

set_rabbitmq_longnames() {
    # Use FQDNs for RabbitMQ clustering
    echo "USE_LONGNAME=true" >> /etc/rabbitmq/rabbitmq-env.conf
}

# Set Erlang cookie for RabbitMQ clustering
set_erlang_cookie() {

    echo "${ERLANG_COOKIE}" > /var/lib/rabbitmq/.erlang.cookie
    chmod 0400 /var/lib/rabbitmq/.erlang.cookie
    chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
}

reboot_if_required() {
    if [[ -f "/var/run/reboot-required" ]]; then
        shutdown -r now
    fi
}

main() {
    set_fqdn
    create_rabbit_volume
    add_rabbit_pkg_source
    add_rabbit_gpg_key
    apt_get_upgrade
    install_rabbitmq
    add_rabbit_mgmt_plugin
    set_rabbitmq_longnames

    rabbitmqctl stop
    set_erlang_cookie
    reboot_if_required

    # RabbitMQ will start on boot
    service rabbitmq-server start
}

main "$@"