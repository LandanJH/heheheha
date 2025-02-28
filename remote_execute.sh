#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!] This script must be run as root (use sudo).${NC}" >&2
    exit 1
fi

if [[ ! -f .env ]]; then
    echo -e "${RED}[!] .env file not found! Exiting.${NC}"
    exit 1
fi

source .env
SCRIPT_DIR="$(pwd)"

execute_remote_scripts() {
    local system_type=$1
    local ip_address=$2

    # Define script directory
    local script_path="$SCRIPT_DIR/$system_type/scripts"

    # Check if script directory exists
    if [[ ! -d "$script_path" ]]; then
        echo -e "${RED}[!] No scripts directory found for $system_type! Skipping.${NC}"
        return
    fi

    # Find all scripts matching the pattern "<system>_linux_<service>.sh"
    scripts=("$script_path"/"${system_type}"_linux_*.sh)

    # Check if any scripts were found
    if [[ ${#scripts[@]} -eq 0 ]]; then
        echo -e "${RED}[!] No scripts found for $system_type! Skipping.${NC}"
        return
    fi

    echo "Executing scripts for $system_type at $ip_address..."

    for script in "${scripts[@]}"; do
        echo -e "${YELLOW}[*] Running $(basename "$script") on $system_type ($ip_address)${NC}"
        ssh -o StrictHostKeyChecking=no "root@$ip_address" "bash -s" < "$script"
    done

    echo "Completed execution for $system_type"
}

# Execute scripts for each system type
[[ -n "$ATM" ]] && execute_remote_scripts "ATM" "$ATM"
[[ -n "$Accounts" ]] && execute_remote_scripts "Accounts" "$Accounts"
[[ -n "$Lockbox" ]] && execute_remote_scripts "Lockbox" "$Lockbox"

echo -e "${GREEN}[*] All remote scripts executed!${NC}"
