# Otpravkarr Docker image — retained release channel

This branch retains historical packaging. Its legacy build and update workflows
are disabled. The maintained build channel is `nightly`; do not treat a nightly
image as a stable release.

For current installation instructions, Docker Compose examples and published
image tags, use the [Otpravkarr container documentation](https://web.edb.fi/containers/otpravkarr/)
and the [maintained nightly README](https://github.com/edbfi/otpravkarr-docker/blob/nightly/README.md).

## Environment Variables

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
