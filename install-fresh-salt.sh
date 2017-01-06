#!/bin/bash

# Ensure working directory is the same as the location of this script
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${dir}"

# Set commands to run with sudo if the running user isn't root
SUDO=

if [ ${EUID} -ne 0 ]
then
    SUDO='sudo'
fi
 
# Download the salt bootstrap
curl -L https://bootstrap.saltstack.com -o bootstrap-salt.sh

# Did we download anything?
if [ ! -s bootstrap-salt.sh ]
then
    echo "ERROR: The salt bootstrap download process did not execute properly!" > /dev/stderr
    exit 1
fi

# Install Salt Master using the bootstrap
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
#${SUDO} sh bootstrap-salt.sh -P -M -L -U -F

# Install Salt Minion using the bootstrap
#   options:
#     -A to pass the master name/IP
#     -F to allow overwrite of configs
#     -i to pass the minion_id
#     -P to allow pip based installs (if packages don't exist for your distro)
#     -p to pass an extra dependency package (one package per -p)
#     -s to pass a sleep time (in seconds) before services are checked
#     -U to fully upgrade the system before bootstrap
#${SUDO} sh bootstrap-salt.sh -P -U -F
