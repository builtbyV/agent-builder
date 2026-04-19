---
name: apple-container
description: Run isolated Linux containers on macOS Apple Silicon via Apple's native `container` CLI. Use when the agent needs a sandboxed shell, an untrusted script runner, or a non-host runtime (Python, Node, etc.) without Docker.
---

# Apple Container (Minimal)

Apple's `container` CLI runs each Linux container in a lightweight VM using the
Containerization framework. No daemon, no Docker Desktop. Apple Silicon + macOS
15+ required (macOS 26+ for full networking).

This skill covers only what `run_in_container` depends on. For the full CLI
reference, see Apple's docs or the upstream apple-container-skill repo.

## Install

```bash
brew install --cask container
```

Verify:

```bash
container --version
container system start         # one-time setup; may prompt for Linux kernel install
container system status
```

## The one command you actually need

```bash
container run --rm [--network none] [-v <host>:<container>[:ro]] [-w <workdir>] <image> sh -lc "<command>"
```

Flags used by `run_in_container`:

| Flag | Meaning |
|---|---|
| `--rm` | Delete the container after exit (always on in the tool) |
| `--network none` | No network egress from the container (default; safest) |
| `--network bridge` | Enable egress (opt-in) |
| `-v host:container[:ro]` | Bind-mount (host side confined to `--cwd` via `safePath`) |
| `-w /path` | Set working directory inside the container |

Example the agent can run directly:

```bash
container run --rm --network none -v $(pwd)/data:/data:ro python:3.12-slim \
  sh -lc "python /data/script.py"
```

## Picking an image

| Use case | Image |
|---|---|
| Generic shell | `alpine:3.20` (tiny, ~5 MB) |
| Python | `python:3.12-slim` |
| Node | `node:22-alpine` |
| No-network linting / parsing | any of the above with `--network none` |

Pull once to warm the cache:

```bash
container image pull python:3.12-slim
```

## Troubleshooting

- `container: command not found` — install with `brew install --cask container`.
- `services not running` — `container system start`.
- `--network` errors on macOS 15 — user-defined networks require macOS 26+; stick with `--network none` or omit the flag.
- Anonymous volumes (`-v /path`, no host side) are NOT cleaned by `--rm` in `container`. `run_in_container` avoids this by always pairing host and container paths.
- Container can't reach the internet — you passed `--network none` (default). Pass `network: "bridge"` in the tool args.

## Gotchas

- `container` is NOT a Docker replacement. It supports the Docker-ish subset of flags `run_in_container` uses; avoid Docker-specific features (`--link`, `--device`, etc.).
- Default container has 1 GiB RAM and 4 CPUs. Override with `--memory` / `--cpus` if needed (the tool does not surface these; edit the agent if you need it).
- All mounts go through the host → lightweight VM → container, which adds a sync step on first access. Small files are fine; gigabyte dirs are not.
