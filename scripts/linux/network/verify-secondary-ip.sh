#!/usr/bin/env bash

#==============================================================================
# SECONDARY IPV4 CONFIGURATION VERIFICATION
#==============================================================================

set -euo pipefail

#==============================================================================
# NETWORK CONFIGURATION
#==============================================================================

secondary_private_ip="${1:-}"
interface_name=$(ip -4 route show default | awk 'NR == 1 { print $5 }')
netplan_file="/etc/netplan/90-shared-secondary-ip.yaml"

if [[ -z "$interface_name" ]]; then
  printf 'Unable to determine the default network interface.\n' >&2
  exit 1
fi

#==============================================================================
# ACTIVE ADDRESS VERIFICATION
#==============================================================================

ip -4 address show dev "$interface_name" | grep -F "inet ${secondary_private_ip}/32"

#==============================================================================
# PERSISTENT CONFIGURATION VERIFICATION
#==============================================================================

sudo -n test -f "$netplan_file"
sudo -n grep -F -- "- ${secondary_private_ip}/32" "$netplan_file"
printf 'secondary_ip=%s\ninterface=%s\npersistence=ready\n' "$secondary_private_ip" "$interface_name"