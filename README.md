# Otpravkarr Docker Image (Nightly)

Nightly images build from the pinned application revision and source checksum in `meta.json`.

Documentation: [web.edb.fi](https://web.edb.fi/containers/otpravkarr/). The inactive release branch is preserved; no stable source tag has been selected.

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
