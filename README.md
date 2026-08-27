<!--
==============================================================================
SHARED HOST AUTOMATION
==============================================================================
-->

# Shared Host Automation

Versioned Linux automation scripts executed on OCI instances through the reusable OCI Run Command workflow. Consumers pin this repository to an immutable release tag and pass only validated arguments; no inbound SSH connection is required.

<!--
==============================================================================
AVAILABLE SCRIPTS
==============================================================================
-->

## Scripts

| Script | Purpose |
|---|---|
| `scripts/linux/cloudflare/bootstrap-cloudflared.sh` | Download a validated immutable release and invoke the connector installer within OCI's payload limit |
| `scripts/linux/cloudflare/install-cloudflared.sh` | Install the pinned connector, expose private metrics, and configure systemd |
| `scripts/linux/network/preflight.sh` | Validate host networking prerequisites |
| `scripts/linux/network/configure-secondary-ip.sh` | Configure a secondary private IP on a host |
| `scripts/linux/network/verify-secondary-ip.sh` | Verify secondary private IP configuration |
| `scripts/linux/oci/bootstrap-oracle-cloud-agent.sh` | Install and validate required Oracle Cloud Agent plugins |

<!--
==============================================================================
CLOUDFLARE TUNNEL CONNECTOR
==============================================================================
-->

## Cloudflare Tunnel Connector

Release `v0.3.1` uses the compact bootstrap as the OCI Run Command entry point. It accepts the immutable repository, release, private metrics address, and Vault-injected Cloudflare Tunnel token in that order.

```shell
bash scripts/linux/cloudflare/bootstrap-cloudflared.sh \
	bharathadigopula/shared-host-automation \
	v0.3.1 \
	10.10.10.3 \
	"$TUNNEL_TOKEN"
```

The production workflow does not place the token in repository configuration. It retrieves the current token from OCI Vault, masks it in GitHub Actions, and appends it as a shell-quoted Run Command argument. The bootstrap downloads the matching tagged source and invokes `install-cloudflared.sh` with the metrics address and token.

<!--
==============================================================================
CONNECTOR REQUIREMENTS
==============================================================================
-->

### Requirements

- Debian package management with `dpkg`
- `curl`, `install`, `sha256sum`, `sudo`, and `systemctl`
- Non-interactive sudo access
- `amd64` or `arm64` architecture
- A private IPv4 address on which Prometheus can reach port `8880`
- A remotely managed Cloudflare Tunnel token containing at least 100 supported characters

<!--
==============================================================================
CONNECTOR BEHAVIOUR
==============================================================================
-->

### Behaviour

The script:

1. Selects the package and pinned SHA-256 checksum for the host architecture.
2. Downloads and installs `cloudflared 2026.8.2` when the installed version differs.
3. Writes the token to root-owned `/etc/cloudflared/tunnel.token` with mode `0600`.
4. Starts cloudflared with `--token-file` so the credential is not present in process arguments.
5. Exposes connector metrics only on `<private-address>:8880`.
6. Installs `/etc/systemd/system/cloudflared.service` with automatic restart enabled.
7. Enables and restarts the service, then confirms both service stability and metrics availability.

Successful output includes:

```text
cloudflared_version=2026.8.2
cloudflared_metrics=ready
cloudflare_tunnel=ready
```

The systemd service uses `--no-autoupdate`; upgrading the connector requires a reviewed script change and a new immutable repository release.

<!--
==============================================================================
REPOSITORY VALIDATION
==============================================================================
-->

## Validation

```shell
SEARCH_PATH=scripts bash ../github-pipeline-templates/scripts/validation/validate-shell.sh
bash scripts/validate.sh
```

The rendered bootstrap and all four arguments must remain within OCI Run Command's 4,096-byte inline command limit. The repository validator uses the maximum supported 255-character secret and also asserts that cloudflared uses only its root-owned token file.

<!--
==============================================================================
RELEASE POLICY
==============================================================================
-->

## Release Policy

- Consumers reference semantic version tags, never `main`.
- Tags are immutable and must not be moved or deleted.
- Script changes require shell validation before release.
- Secrets must be injected at runtime and must not be committed, printed, or included in workflow artifacts.
