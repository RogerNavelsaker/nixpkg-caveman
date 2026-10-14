# nixpkg-caveman

Nix packages and a rootless OCI image for the Caveman developer CLI and local service runtime. These are separate upstream products and deliberately use separate outputs:

- `packages.caveman-cli`: official `@caveman-ai/cli` 4.0.1 wrapped with Bun. It exposes `caveman` and `cave`, defaults telemetry off with `DO_NOT_TRACK=1`, and keeps the six runtime helper binaries private to the wrapper.
- `packages.caveman` / `packages.caveman-service`: Caveman proxy and MCP binaries from `bin-v2.1.0`.
- `packages.caveman-image`: rootless OCI image `agent-services-caveman`, running as UID/GID 10001 with persistent recovery data at `/data`.

The service listens on port 8787 and requires a runtime token for non-loopback access. Supply it as a container secret; keep provider credentials runtime-only. The MCP server is stdio-only and should use the same persistent data directory as the proxy.

## Build and verify

```sh
nix flake check --accept-flake-config
nix build .#caveman .#caveman-image --no-link
nix build .#caveman-cli --no-link # x86_64-linux
```

The CLI derivation checks `--version` and `setup --json` without calling an external model. The image retains the existing GHCR name `ghcr.io/rogernavelsaker/agent-services-caveman`.

The `publish.yml` workflow is manual-only; it publishes `latest` and a commit-SHA tag. The split does not publish images or replace existing tags.
