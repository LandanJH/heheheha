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

if [ "$#" -ne 2 ]; then
    echo -e "${RED}[!] Usage: $0 <old_password> <new_password>"
    exit 1
fi

ipv6() {
    # Disable IPv6 by modifying sysctl configuration
    echo -e "${YELLOW}[!] Disabling IPv6 via sysctl... ${NC}"
    echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf > /dev/null
    echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf > /dev/null
    echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf > /dev/null

    sudo sysctl -p

    # Disable IPv6 via GRUB
    echo -e "${YELLOW}[!] Disabling IPv6 via GRUB... ${NC}"
    sudo sed -i 's/^GRUB_CMDLINE_LINUX=".*"/GRUB_CMDLINE_LINUX="ipv6.disable=1"/' /etc/default/grub

    sudo update-grub

    # THIS WILL NEED A REBOOT TO APPLY
}

check() {
    VALUE=$(lsmod | grep conntrack)
    if [ -z "$VALUE" ]; then
        echo -e "${BLUE} conntrack is not loaded, installing and configuring... ${NC}"
        sudo apt install conntrack -y
        echo "nf_conntrack" | sudo tee -a /etc/modules
        sudo modprobe nf_conntrack_ftp  ## CONFIGURE THIS FURTHER FOR Lockbox
    else
        echo -e "${BLUE} conntrack is loaded, configuring... ${NC}"
        ## COMMANDS
    fi
}

rules() {
    echo -e "${YELLOW}  [!] Setting up default firewall rules ${NC}"
    # Default rules
    sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

    # contrack stuff
    sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED, RELATED -j ACCEPT
    #sudo iptables -A INPUT -m conntrack --ctstate NEW -j DROP # need to see if this is allowed???

    # other
}

save() {
    sudo apt install iptables-persistent -y
    sudo service iptables save
    sudo iptables-save > /etc/iptables/rules.v4
    sudo chattr +i /etc/iptables/rules.v4
    echo -e "${BLUE}  [*] Reminder that you will need to unchattr this file to change it ${NC}"
}

accounts() {

    old_password="$1"
    new_password="$2"

    account_names=("test1" "test2")
    #account_names=("goon1" "goon2" "hacker" "buyer" "lockpick" "safecracker" "root")
    #account_names=("goon1" "goon2" "hacker" "buyer" "lockpick" "safecracker" "getaway" "driver" "watchdog" "manager" "mastermind" "root")
    for account_name in "${account_names[@]}"; do
        echo "Changing password for $account_name..."
        
        # Use chpasswd to change password
        echo "$account_name:$new_password" | sudo chpasswd
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}  [*] Password changed for $account_name ${NC}"
        else
            echo -e "${RED}  [!] Failed to change password for $account_name ${NC}"
        fi
    done

}

clean() {
    sudo history -c && history -w
}

main() {
    ipv6
    check
    rules
    accounts "$1" "$2"
    save
    clean
    echo -e "${GREEN}[*] default configurations completed! ${NC}"
    echo -e "${RED}[!!!] YOU WILL NEED TO REBOOT THE BOX FOR CONFIGS TO SAVE ${NC}"
}

main "$1" "$2"
