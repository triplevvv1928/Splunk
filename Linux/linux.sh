#!/bin/sh  
# This script shows how to deploy the Splunk universal forwarder
# to many remote hosts via ssh and common Unix commands.
# For "real" use, this script needs ERROR DETECTION AND LOGGING!!
# --Variables that you must set -----

# Populate this file with a list of hosts that this script should install to,
# with one host per line. This must be specified in the form that should
# be used for the ssh login, ie. username@host
#
# Example file contents:
# splunkuser@10.20.13.4
# splunkker@10.20.13.5
  HOSTS_FILE="uf_hosts/uf_hosts.conf"

# This should be a WGET command that was *carefully* copied from splunk.com!!
# Sign into splunk.com and go to the download page, then look for the wget
# link near the top of the page (once you have selected your platform)
# copy and paste your wget command between the ""
  WGET_CMD="wget -O splunkforwarder-7.3.1-bd63e13aa157-Linux-x86_64.tgz 'https://d7wz6hmoaavd0.cloudfront.net/products/universalforwarder/releases/7.3.1/linux/splunkforwarder-7.3.1-bd63e13aa157-Linux-x86_64.tgz'"
# Set the install file name to the name of the file that wget downloads
# (the second argument to wget)
  INSTALL_FILE="splunkforwarder-7.3.1-bd63e13aa157-Linux-x86_64.tgz"

# After installation, the forwarder will become a deployment client of this
# host.  Specify the host and management (not web) port of the deployment server
# that will be managing these forwarder instances.
# Example 1.2.3.4:8089
  DEPLOY_SERVER="x.x.x.x:8089"

# Forward Server
  FORWARD_SERVER="X.X.X.X:9997"


# Set the seed app folder name for deploymentclien.conf
  DEPLOY_APP_FOLDER_NAME="seed_all_deploymentclient"
# Set the new Splunk admin password
  PASSWORD="newpassword"

REMOTE_SCRIPT_DEPLOY="
  cd /opt
  sudo $WGET_CMD
  sudo tar xvzf $INSTALL_FILE -C /opt
  sudo rm -rf $INSTALL_FILE
  echo \"[user_info]
USERNAME = admin
PASSWORD = $PASSWORD\" > /opt/splunkforwarder/etc/system/local/user-seed.conf  
  mkdir -p /opt/splunkforwarder/etc/apps/$DEPLOY_APP_FOLDER_NAME/local
  echo \"[deployment-client]
[target-broker:deploymentServer]
targetUri = $DEPLOY_SERVER\" > /opt/splunkforwarder/etc/apps/$DEPLOY_APP_FOLDER_NAME/local/deploymentclient.conf
  sudo -u $SPLUNK_RUN_USER /opt/splunkforwarder/bin/splunk start --accept-license
  sudo /opt/splunkforwarder/bin/splunk enable boot-start
  sudo /opt/splunkforwarder/bin/splunk add forward-server $FORWARD_SERVER
  exit
 "

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#===============================================================================================
  echo "In 5 seconds, will run the following script on each remote host:"
  echo
  echo "===================="
  echo "$REMOTE_SCRIPT_DEPLOY"
  echo "===================="
  echo 
  sleep 5
  echo "Reading host logins from $HOSTS_FILE"
  echo
  echo "Starting."
  for DST in `cat "$DIR/$HOSTS_FILE"`; do
    if [ -z "$DST" ]; then
      continue;
    fi
    echo "---------------------------"
    echo "Installing to $DST"
    echo "Initial UF deployment"
    sudo ssh -t "$DST" "$REMOTE_SCRIPT_DEPLOY"
  done  
  echo "---------------------------"
  echo "Done"
  echo "Please use the following app folder name to override deploymentclient.conf options: $DEPLOY_APP_FOLDER_NAME"
