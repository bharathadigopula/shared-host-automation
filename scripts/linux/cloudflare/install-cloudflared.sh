#!/usr/bin/env bash

#==============================================================================
# CLOUDFLARE TUNNEL CONNECTOR
#==============================================================================

set -euo pipefail

tunnel_token="${1:-}"
cloudflared_version="2026.8.2"

if [[ ! "$tunnel_token" =~ ^[A-Za-z0-9._=-]{100,}$ ]]; then
  printf 'A valid Cloudflare tunnel token is required.\n' >&2
  exit 10
fi

for required_command in curl dpkg install sha256sum sudo systemctl; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'Required command is unavailable: %s\n' "$required_command" >&2
    exit 20
  fi
done

if ! sudo -n true; then
  printf 'The automation user does not have non-interactive sudo access.\n' >&2
  exit 30
fi

#==============================================================================
# PINNED PACKAGE INSTALLATION
#==============================================================================

case "$(dpkg --print-architecture)" in
  amd64)
    package_architecture="amd64"
    expected_sha256="c805c7c8102190c04dfc16e3b4cc4acc9007d5b19b3afbcd608ea6fed7645a43"
    ;;
  arm64)
    package_architecture="arm64"
    expected_sha256="096739c69f62cace40b144f0e6c81e61333f3d320ce07a265c7b17b5e925731c"
    ;;
  *)
    printf 'Unsupported package architecture.\n' >&2
    exit 40
    ;;
esac

installed_version=$(cloudflared --version 2>/dev/null | awk '{ print $3 }' || true)
if [[ "$installed_version" != "$cloudflared_version" ]]; then
  package_file=$(mktemp --suffix=.deb)
  trap 'rm -f "$package_file"' EXIT
  package_url="https://github.com/cloudflare/cloudflared/releases/download/${cloudflared_version}/cloudflared-linux-${package_architecture}.deb"
  curl --fail --location --silent --show-error "$package_url" --output "$package_file"
  printf '%s  %s\n' "$expected_sha256" "$package_file" | sha256sum --check --status
  sudo -n dpkg --install "$package_file"
  rm -f "$package_file"
  trap - EXIT
fi

installed_version=$(cloudflared --version | awk '{ print $3 }')
if [[ "$installed_version" != "$cloudflared_version" ]]; then
  printf 'Installed cloudflared version %s does not match required version %s.\n' "$installed_version" "$cloudflared_version" >&2
  exit 45
fi

#==============================================================================
# SYSTEMD SERVICE
#==============================================================================

token_file=$(mktemp)
unit_file=$(mktemp)
trap 'rm -f "$token_file" "$unit_file"' EXIT

printf 'TUNNEL_TOKEN=%s\n' "$tunnel_token" > "$token_file"
chmod 600 "$token_file"

cat > "$unit_file" <<'UNIT'
[Unit]
Description=Cloudflare Tunnel
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
EnvironmentFile=/etc/cloudflared/tunnel.env
ExecStart=/usr/bin/cloudflared --no-autoupdate tunnel run --token ${TUNNEL_TOKEN}
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
UNIT

sudo -n install -d -o root -g root -m 700 /etc/cloudflared
sudo -n install -o root -g root -m 600 "$token_file" /etc/cloudflared/tunnel.env
sudo -n install -o root -g root -m 644 "$unit_file" /etc/systemd/system/cloudflared.service
sudo -n systemctl daemon-reload
sudo -n systemctl enable cloudflared.service
sudo -n systemctl restart cloudflared.service

for attempt in {1..30}; do
  if sudo -n systemctl is-active --quiet cloudflared.service; then
    sleep 5
    if sudo -n systemctl is-active --quiet cloudflared.service; then
      break
    fi
  fi

  if (( attempt == 30 )); then
    sudo -n systemctl status cloudflared.service --no-pager >&2
    exit 50
  fi

  sleep 2
done

printf 'cloudflared_version=%s\n' "$installed_version"
printf 'cloudflare_tunnel=ready\n'