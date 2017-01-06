#!/bin/bash

# Ensure working directory is the same as the location of this script
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${dir}"

# FUNCTION: detect_os
detect_os() {
}

# FUNCTION: get_pkg_mgr
get_pkg_mgr() {
}

# Set commands to run with sudo if the running user isn't root
SUDO=

if [[ ${EUID} -ne 0 && $(which sudo) ]]
then
    SUDO='sudo'
fi

# Set variables for Salt install
minion_id="$(hostname -f 2> /dev/null || hostname)"
salt_master="localhost"
 
# Download the salt bootstrap
if [ $(which curl) ]
then
    curl -L https://bootstrap.saltstack.com -o bootstrap-salt.sh
elif [ $(which wget) ]
then
    wget -O bootstrap-salt.sh https://bootstrap.saltstack.com
fi

# Did we download anything?
if [ ! -s bootstrap-salt.sh ]
then
    echo "ERROR: The salt bootstrap download process did not execute properly!" > /dev/stderr
    exit 1
fi

# Install Salt Master, Minion, and Cloud using the bootstrap
#   options:
#     -A to pass the master name/IP
#     -F to allow overwrite of configs
#     -i to pass the minion_id
#     -k to pass a directory of preseed keys for the minions
#     -L to install salt-cloud and python-libcloud
#     -M to install salt-master
#     -P to allow pip based installs (if packages don't exist for your distro)
#     -p to pass an extra dependency package (one package per -p)
#     -s to pass a sleep time (in seconds) before services are checked
#     -U to fully upgrade the system before bootstrap
#${SUDO} sh bootstrap-salt.sh -P -M -L -U -F -A "${salt_master}" -i "${minion_id}"

# Install Salt Minion using the bootstrap
#   options:
#     -A to pass the master name/IP
#     -F to allow overwrite of configs
#     -i to pass the minion_id
#     -P to allow pip based installs (if packages don't exist for your distro)
#     -p to pass an extra dependency package (one package per -p)
#     -s to pass a sleep time (in seconds) before services are checked
#     -U to fully upgrade the system before bootstrap
#${SUDO} sh bootstrap-salt.sh -P -U -F -A "${salt_master}" -i "${minion_id}"

# Install git if necessary
if [ ! $(which git) ]
then
    pkg_mgr="$(get_pkg_mgr)"
    if [ -z "${pkg_mgr}" ]
    then
        echo "ERROR: Unable to find a package manager to install git!" > /dev/stderr
        exit 1
    else
        ${SUDO} ${pkg_mgr} install git
    fi
fi

# Clone salt-internal to /srv/salt


# Edit the salt-cloud pillar files?
# /srv/salt/pillar/salt/cloud-*

# Generate salt-cloud configurations
salt-call state.sls salt.sshkeys
salt-call state.sls salt.cloud_providers
salt-call state.sls salt.cloud_profiles
salt-call state.sls salt.cloud_maps
salt-call state.sls salt.rosters
salt-call state.sls salt.cache

