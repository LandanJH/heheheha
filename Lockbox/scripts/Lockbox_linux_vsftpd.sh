#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!] This script must be run as root ${NC}"
    exit 1
fi

#vars
CONFIG_FILE="/etc/vsftpd.conf"
NEW_CONFIG_FILE="../configs/vsftpd.conf"
CONFIG_FILE_BACKUP="../configs/vsftpd.conf.original"
EMPTY_DIR="/usr/local/share/vsftpd/empty"

# getting things ready for the rest of the script
setup() {
    echo -e "${YELLOW}  [!] Changing and saving the old configuration file ${NC}"
    sudo mkdir -p $EMPTY_DIR
    sudo chown root:root $EMPTY_DIR
    sudo chmod 755 $EMPTY_DIR
    sudo chattr -i $NEW_CONFIG_FILE || { echo "failed to remove immutable attribute from new conf file, this should be fine just a check"; }
    sudo chattr -i $CONFIG_FILE || { echo "failed to remove immutable attribute from original conf file, this should be fine just a check"; }
    sudo cp $CONFIG_FILE $CONFIG_FILE_BACKUP
    sudo rm $CONFIG_FILE
}

# switch the configs to set a "jail" and remove anonymous logon
switch_config() {
    echo -e "${YELLOW}  [!] Switching to the new configuration file ${NC}"
    sudo cp $NEW_CONFIG_FILE $CONFIG_FILE || { echo "Failed to copy new config"; exit 1; }
}

# make the file immutable, preventing changes
chattr_file() {
    echo -e "${YELLOW}  [!] Editing the permissions on the new config to prevent changes ${NC}"
    sudo chown root:root $CONFIG_FILE || { echo "Failed to change permissions"; exit 1; }
    sudo chmod 644 $CONFIG_FILE || { echo "Failed to change permissions"; exit 1; }
    sudo chattr +i $CONFIG_FILE || { echo "Failed to set immutable flag"; exit 1; }
}

commit_changes() {
    echo -e "${YELLOW}  [!] Restarting vsFTPD service ${NC}"
    sudo systemctl restart vsftpd.service
}

main() {
    setup
    switch_config
    chattr_file
    commit_changes
    echo -e "${GREEN}[*] vsFTPD Setup Completed! ${NC}"
}

main
