#!/usr/bin/env bash

#==============================================================================
# LINUX NETWORK AUTOMATION PREFLIGHT
#==============================================================================

set -euo pipefail

#==============================================================================
# NETWORK ENVIRONMENT
#==============================================================================

printf 'user=%s\n' "$(id -un)"
printf 'kernel=%s\n' "$(uname -r)"
printf 'default_interface=%s\n' "$(ip -4 route show default | awk 'NR == 1 { print $5 }')"
command -v netplan
ip -4 address show scope global

#==============================================================================
# PRIVILEGED AUTOMATION
#==============================================================================

if ! sudo -n true; then
  printf 'The automation user does not have non-interactive sudo access.\n' >&2
  exit 20
fi

printf 'privileged_automation=ready\n'