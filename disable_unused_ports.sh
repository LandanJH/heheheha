#!/bin/bash

# Ensure script runs with sudo
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (use sudo)." >&2
    exit 1
fi

# List of allowed ports (modify as needed)
ALLOWED_PORTS=(2222 80)  # Add any other necessary ports

# Detect open ports (excluding LISTEN status)
OPEN_PORTS=$(ss -tuln | awk 'NR>1 {print $5}' | awk -F: '{print $NF}' | sort -nu)

# Alternative for older systems without `ss`
if [[ -z "$OPEN_PORTS" ]]; then
    OPEN_PORTS=$(netstat -tuln | awk 'NR>2 {print $4}' | awk -F: '{print $NF}' | sort -nu)
fi

# Iterate through open ports and disable unused ones
for port in $OPEN_PORTS; do
    if [[ ! " ${ALLOWED_PORTS[@]} " =~ " ${port} " ]]; then
        echo "Disabling unused port: $port"
        ufw deny $port/tcp
        ufw deny $port/udp
    fi
done

# Enable UFW if not already enabled
ufw enable

# Reload UFW rules
ufw reload

echo "Unused ports have been disabled."
