#!/usr/bin/env bash

#==============================================================================
# VERSIONED CLOUDFLARE CONNECTOR BOOTSTRAP
#==============================================================================

#==============================================================================
# SHELL SAFETY
#==============================================================================

set -euo pipefail

#==============================================================================
# BOOTSTRAP INPUTS
#==============================================================================

automation_repository="${1:-}"
automation_ref="${2:-}"
metrics_address="${3:-}"
metrics_source_address="${4:-}"
tunnel_token="${5:-}"

if [[ ! "$automation_repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || \
  [[ ! "$automation_ref" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'A valid automation repository and release are required.\n' >&2
  exit 1
fi

#==============================================================================
# VERSIONED SOURCE DOWNLOAD
#==============================================================================

temporary_root=$(mktemp -d)
trap 'rm -rf "$temporary_root"' EXIT
curl --fail --location --silent --show-error \
  "https://github.com/$automation_repository/archive/refs/tags/$automation_ref.tar.gz" \
  --output "$temporary_root/source.tar.gz"
mkdir "$temporary_root/source"
tar --extract --gzip --file "$temporary_root/source.tar.gz" \
  --directory "$temporary_root/source" --strip-components=1

#==============================================================================
# CONNECTOR INSTALLATION
#==============================================================================

bash "$temporary_root/source/scripts/linux/cloudflare/install-cloudflared.sh" \
  "$metrics_address" "$metrics_source_address" "$tunnel_token"