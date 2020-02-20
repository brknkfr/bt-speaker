#!/bin/bash +x
set -e

# This script has been tested with the "2018-06-27-raspbian-stretch-lite.img" image.

echo "Installing dependencies..."
apt-get update
apt-get --yes install git bluez python python-gobject python-cffi python-dbus python-configparser pulseaudio-module-bluetooth espeak-ng
echo "done."

# Add btspeaker user if not exist already
echo
echo "Adding btspeaker user..."
id -u bt-speaker &>/dev/null || useradd bt-speaker -m -G audio
# Also add user to bluetooth group if it exists (required in debian stretch)
getent group bluetooth &>/dev/null && usermod -a -G bluetooth bt-speaker -d /opt/bt-speaker
echo "done."

# Download bt-speaker to /opt (or update if already present)
echo
cd /opt
if [ -d bt-speaker ]; then
  echo "Folder already exists ..."
  cd bt-speaker
  echo "Update manually with git pull && git checkout ${1:master} as bt-speaker"
  exit 1
else
  echo "Downloading bt-speaker..."
  git clone https://github.com/brknkfr/bt-speaker.git
  cd bt-speaker && git checkout ${1:master}
fi
echo "done."

# Prepare default config
mkdir -p /etc/bt_speaker/hooks
cp -n /opt/bt-speaker/config.ini.default /etc/bt_speaker/config.ini
cp -n /opt/bt-speaker/hooks.default/startup /etc/bt_speaker/hooks/startup
cp -n /opt/bt-speaker/hooks.default/connect /etc/bt_speaker/hooks/connect
cp -n /opt/bt-speaker/hooks.default/disconnect /etc/bt_speaker/hooks/disconnect

# Change permissions
chown -R bt-speaker:bt-speaker -R /opt/bt-speaker
chown -R bt-speaker:root -R /etc/bt_speaker

# Install and start bt-speaker daemon
echo
echo "Registering and starting bt-speaker with systemd..."
systemctl enable /opt/bt-speaker/bt_speaker.service
if [ "`systemctl is-active bt_speaker`" != "active" ]; then
  systemctl start bt_speaker
else
  systemctl restart bt_speaker
fi
  systemctl status bt_speaker --full --no-pager
echo "done."

# Finished
echo
echo "BT-Speaker has been installed."
