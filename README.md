# Shared Host Automation

Versioned Linux automation scripts executed on OCI instances through the reusable OCI Run Command workflow. Consumers pin this repository to an immutable release tag and pass only validated arguments; no inbound SSH connection is required.

## Scripts

| Script | Purpose |
|---|---|
| `scripts/linux/cloudflare/install-cloudflared.sh` | Install and run the pinned Cloudflare Tunnel connector |
| `scripts/linux/network/preflight.sh` | Validate host networking prerequisites |
| `scripts/linux/network/configure-secondary-ip.sh` | Configure a secondary private IP on a host |
| `scripts/linux/network/verify-secondary-ip.sh` | Verify secondary private IP configuration |
| `scripts/linux/oci/bootstrap-oracle-cloud-agent.sh` | Install and validate required Oracle Cloud Agent plugins |

## Cloudflare Tunnel Connector

Release `v0.3.0` provides `scripts/linux/cloudflare/install-cloudflared.sh`. The script accepts the Cloudflare Tunnel token as its first and only argument.

```shell
bash scripts/linux/cloudflare/install-cloudflared.sh "$TUNNEL_TOKEN"
```

The production workflow does not place the token in repository configuration. It retrieves the current token from OCI Vault, masks it in GitHub Actions, and appends it as a shell-quoted Run Command argument.

### Requirements

- Debian package management with `dpkg`
- `curl`, `install`, `sha256sum`, `sudo`, and `systemctl`
- Non-interactive sudo access
- `amd64` or `arm64` architecture
- A remotely managed Cloudflare Tunnel token containing at least 100 supported characters

### Behaviour

The script:

1. Selects the package and pinned SHA-256 checksum for the host architecture.
2. Downloads and installs `cloudflared 2026.8.2` when the installed version differs.
3. Writes the token to root-owned `/etc/cloudflared/tunnel.env` with mode `0600`.
4. Installs `/etc/systemd/system/cloudflared.service` with automatic restart enabled.
5. Enables and restarts the service.
6. Confirms the service remains active and emits the required readiness markers.

Successful output includes:

```text
cloudflared_version=2026.8.2
cloudflare_tunnel=ready
```

The systemd service uses `--no-autoupdate`; upgrading the connector requires a reviewed script change and a new immutable repository release.

## Validation

```shell
bash -n scripts/linux/cloudflare/install-cloudflared.sh
shellcheck scripts/linux/cloudflare/install-cloudflared.sh
```

The complete script plus arguments must remain within OCI Run Command's 4,096-byte inline command limit.

## Release Policy

- Consumers reference semantic version tags, never `main`.
- Tags are immutable and must not be moved or deleted.
- Script changes require shell validation before release.
- Secrets must be injected at runtime and must not be committed, printed, or included in workflow artifacts.
