# Otpravkarr Docker image — retained release channel

This branch retains historical packaging. Its legacy build and update workflows
are disabled. The maintained build channel is `nightly`; do not treat a nightly
image as a stable release.

For current installation instructions, Docker Compose examples and published
image tags, use the [Otpravkarr container documentation](https://web.edb.fi/containers/otpravkarr/)
and the [maintained nightly README](https://github.com/edbfi/otpravkarr-docker/blob/nightly/README.md).

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

## License

- Docker packaging: [GPL-3.0 license](LICENSE).
- Application: [AGPL-3.0 source repository](https://github.com/edbfi/otpravkarr).
