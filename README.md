# Otpravkarr Docker Image (Nightly)

Nightly images build from the pinned application revision and source checksum in `meta.json`.

Documentation: [web.edb.fi](https://web.edb.fi/containers/otpravkarr/). The inactive release branch is preserved; no stable source tag has been selected.

## Environment Variables

### `ORIGIN`

Set `ORIGIN` to the address people open in the browser, for example `http://192.168.1.10:3000`. It is **required when serving plain HTTP**: without it Otpravkarr assumes `https://<Host>`, so signing in and saving changes fail. Leave it unset only behind an HTTPS reverse proxy that passes the original `Host`. It must be a bare origin (no path, query or credentials), or the app does not start.

```yaml
environment:
  - ORIGIN=http://192.168.1.10:3000
```

Behind a reverse proxy, set `ADDRESS_HEADER=x-forwarded-for` (and `XFF_DEPTH` to the number of proxies, default `1`) only when every request goes through that proxy, so the app sees the real client address. `PROTOCOL_HEADER` and `HOST_HEADER` are for setups without `ORIGIN`, behind a trusted proxy.

### `SHUTDOWN_TIMEOUT`

Seconds the app waits for open requests when the container stops. The image sets `5` so a plain `docker stop` (10 s) finishes cleanly; if you raise it, raise the stop timeout too (`docker stop -t`, `stop_grace_period`).

### `OTPRAVKARR_SECRET` (required)

A stable secret of at least **32 characters** that persists across container restarts. The container will refuse to start if this variable is unset or too short.

> **Warning:** This value must remain stable. It derives the AES-GCM keys used to encrypt configuration (e.g. Plex admin token, Dispatcharr API key) and per-user Xtream passwords. If it changes, all previously-encrypted rows become permanently unreadable.

Generate one with:

```sh
openssl rand -base64 48
```

Then provide it via your compose file or an env file kept outside version control:

```yaml
environment:
  - OTPRAVKARR_SECRET=<paste value here>
```

## Building

`.github/workflows/build-nightly.yml` is the caller edbfi/base-image uses for itself, under its own name. It runs on every push to a branch that carries it, except a branch named `workflows`, and calls the shared build workflow in [edbfi/base-image](https://github.com/edbfi/base-image): it builds linux/amd64 and linux/arm64 on GitHub-hosted runners, smoke-tests each image with the `test_amd64`, `test_arm64` and `test_url` settings in `meta.json`, and publishes the images to `ghcr.io/edbfi/otpravkarr-docker`, tagged with the branch name. A push to `nightly` therefore publishes the `nightly` image. A push to any other branch cut from `nightly` would publish under that branch's name, so push changes to this workflow on a branch named `workflows`, which never builds.

`./build.sh` stays for local builds: run `./build.sh amd64` or `./build.sh arm64` from the repository root. It needs `docker` and `jq`, passes the `meta.json` keys as build arguments, and the Dockerfiles verify the source archive against `source_sha256`.
