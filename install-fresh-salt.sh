#!/bin/bash

############################################################################
#                                                                          #
# NAME:        Install Fresh Salt                                          #
#                                                                          #
# DESCRIPTION: This script downloads the SaltStack bootstrap script and    #
#              executes it with options for Salt Master, Salt Cloud, and   #
#              a Salt Minion pointing at itself. We also pull down some    #
#              stuff from Git. This script requires interactive input from #
#              a user with escalated privileges or sudo.                   #
#                                                                          #
# REVISIONS:   2017-01-06 - N - Initial creation                           #
#                                                                          #
############################################################################


# Ensure working directory is the same as the location of this script
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${dir}"

# FUNCTION: get_pkg_mgr
get_pkg_mgr() {
    local p=
    # shellcheck disable=SC2046
    if [ $(which yum) ]
    then
        p="yum"
    elif [ $(which apt-get) ]
    then
        p="apt-get"
    fi
    echo "$p"
}

# Check for a package manager. This logic is separate from the bootstrap
pkg_mgr="$(get_pkg_mgr)"

# Set commands to run with sudo if the running user isn't root
SUDO=

if [[ ${EUID} -ne 0 && $(which sudo) ]]
then
    SUDO='sudo'
elif [[ ${EUID} -ne 0 && ! $(which sudo) ]]
then
    echo "ERROR: You aren't root and I can't find sudo... You probably can't install anything!" > /dev/stderr
    exit 1
fi

# Set variables for Salt install. Static for now, but may want to take input later
minion_id="$(hostname -f 2> /dev/null || hostname)"
salt_master="localhost"
 
# Download the salt bootstrap
# Try twice and then die
for (( attempt=1; attempt<3; attempt++ ))
do
    # shellcheck disable=SC2046
    if [ $(which curl) ]
    then
        curl -L https://bootstrap.saltstack.com -o bootstrap-salt.sh
        break
    elif [ $(which wget) ]
    then
        wget -O bootstrap-salt.sh https://bootstrap.saltstack.com
        break
    else
        if [ -z "${pkg_mgr}" ]
        then
            echo "ERROR: Unable to find a package manager to install curl/wget!" > /dev/stderr
            echo "ERROR: Unable to download the Salt bootstrap." > /dev/stderr
            exit 1
        else
            # shellcheck disable=SC2086
            ${SUDO} ${pkg_mgr} install -y -q curl wget
        fi
    fi
done

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
${SUDO} sh bootstrap-salt.sh -P -M -L -U -F -A "${salt_master}" -i "${minion_id}"
retval=$?

# Did the bootstrap succeed?
if [ ${retval} -ne 0 ]
then
    echo "ERROR: The Salt bootstrap exited abnormally! Please check your install." > /dev/stderr
    exit 1
fi

# Drop a custom master config file
cat << EOF > /etc/salt/master.d/99-freshsalt-pillarloc.conf
pillar_roots:
  base:
    - /srv/salt/pillar
EOF

# Restart the salt-master service
# shellcheck disable=SC2046
if [ $(which systemctl) ]
then
    ${SUDO} systemctl restart salt-master
elif [ -f /sbin/service ]
then
    ${SUDO} /sbin/service salt-master restart
elif [ -f /etc/init.d/salt-master ]
then
    ${SUDO} /etc/init.d/salt-master restart
else
    echo "WARN: Unable to find a command to restart the Salt Master!" > /dev/stderr
    echo "INFO: Your pillar data will be in the 'wrong' place until the service can be restarted." > /dev/stderr
    echo "INFO: Continuing anyway..." > /dev/stderr
    sleep 5
fi

# Accept the local key
sleep 10
salt-key -a "$(cat /etc/salt/minion_id)" -y

# Install git if necessary
# shellcheck disable=SC2046
if [ ! $(which git) ]
then
    if [ -z "${pkg_mgr}" ]
    then
        echo "ERROR: Unable to find a package manager to install git!" > /dev/stderr
        echo "ERROR: Salt was installed, but you'll need to pull in " > /dev/stderr
        echo "       states, etc. manually." > /dev/stderr
        exit 1
    else
        # shellcheck disable=SC2086
        ${SUDO} ${pkg_mgr} install -y -q git
    fi
fi

# Clone salt-internal to /srv/salt
# This will prompt the user for credentials
${SUDO} mkdir -m 755 /srv 2> /dev/null
cd /srv/
git clone https://github.com/DecisionLab/salt-internal.git
mv salt{-internal,}
${SUDO} chown -R root: salt
cd -

# Edit these files:
# /srv/salt/pillar/salt/cloud-*
# ...per https://docs.saltstack.com/en/latest/topics/cloud/#configuration
# IF you don't have them in git (which we should)

# Generate salt-cloud configurations
if [[ $(find /srv/salt/pillar/salt/cloud-* 2> /dev/null | wc -l) -gt 0 ]]
then
    salt-call state.sls salt.sshkeys
    salt-call state.sls salt.cloud_providers
    salt-call state.sls salt.cloud_profiles
    salt-call state.sls salt.cloud_maps
    salt-call state.sls salt.rosters
    salt-call state.sls salt.cloud_cache
fi

# Clean up after yourself
rm -f bootstrap-salt.sh

exit 0


# SAVING THIS FOR LATER... Right now, we're only installing the Salt Master. Maybe
# we want to have an option for a Minion install that has extra stuff?
#
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
#retval=$?
