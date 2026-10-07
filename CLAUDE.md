# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Which branch you are on matters

Packaging-only repo for the Otpravkarr image: no application source here. Both Dockerfiles download
`https://github.com/edbfi/otpravkarr/archive/${VERSION}.tar.gz` and build it in a `oven/bun:alpine` stage.

`release` (the default branch) builds otpravkarr's latest published, non-prerelease GitHub Release
with a plain `X.Y.Z` tag (`version__command` reads `releases/latest`; a bare tag publishes nothing);
`nightly` builds the latest commit on `main`. Publish a backport release with "Set as the latest
release" unchecked, or `release` moves back to that version. Both follow Hotio's layout and are built
by the same workflows: `.github/workflows/call-build.yml` builds and publishes an image on every push
to any branch except `workflows`, and `call-update.yml` refreshes `meta.json` hourly. The two branches
differ only in `meta.json`'s channel values (`description`, `latest`, `version`, `version__command`),
in `README.md`, and in files that exist only on `release`: this file, `AGENTS.md`,
`.github/workflows/pullfrog.yml` and `.github/workflows/immortality.yml`. Keep everything else
identical: port a fix to the Dockerfiles, `build.sh` or `root/` to both branches.

## Commands

No manifest, test suite, linter or formatter exists. The only validation is a Docker build:

```sh
./build.sh amd64   # or arm64; needs docker + jq; tags "<repo-dir-name>-amd64"
```

`build.sh` turns every `meta.json` key except the `*__command` keys into an uppercase `--build-arg`;
`./build.sh update` evaluates the `*__command` keys the way `call-update` does and rewrites
`meta.json`. Until otpravkarr publishes its first plain `X.Y.Z` release, `release`'s `meta.json` has
`"version": "null"`, so the builder (local and `call-build`) fetches `archive/null.tar.gz` and fails.
To build locally, put a real upstream ref in `version` and don't commit that edit.

## meta.json

- The Dockerfiles consume only `VERSION`, `UPSTREAM_IMAGE`, `UPSTREAM_TAG_SHA` and `IMAGE_STATS`.
  Besides `build.sh`, nothing in this repo reads the other keys; the called workflows in
  `edbfi/base-image@workflows` do.
- `version` and `upstream_tag_sha` are values that `github-actions[bot]` resolved from the matching
  `*__command` shell snippet (the `Modified: meta.json` commits). To change how a value is found,
  edit the `__command` string, not the value.
- `packages.txt` is bot-generated and empty. Don't hand-edit it.

## Container runtime contract

- `APP_DIR`, `CONFIG_DIR`, `UMASK`, the `hotio` user, `/etc/s6-overlay/scripts/bash-functions`,
  and the `init-setup` / `init-wireguard` units all come from the base image
  (`ghcr.io/edbfi/base-image:alpinevpn`), so none are defined in this repo. Use the variables;
  don't hardcode the paths they resolve to.
- Persistence is a symlink: the Dockerfile replaces `${APP_DIR}/data` with a link to
  `${CONFIG_DIR}/data`. Keep it, or app data stops landing under `${CONFIG_DIR}`.
- `OTPRAVKARR_SECRET` must stay a hard requirement. `init-setup-app/run` exits when it is unset or
  shorter than 32 chars, because it derives the encryption keys for stored config and per-user passwords.
  Never add a default or auto-generated fallback: a changed secret makes existing encrypted rows
  unreadable.
- Services drop privileges with `exec s6-setuidgid hotio ...` (see `service-otpravkarr/run`).

## Adding an s6 service

1. `root/etc/s6-overlay/s6-rc.d/<name>/type`: `oneshot` or `longrun`.
2. `<name>/run` starting with `#!/command/with-contenv bash`. For a `oneshot`, also add `up` that
   holds the absolute in-container path of that `run` (copy `init-setup-app/up`).
3. Ordering: an empty file `<name>/dependencies.d/<dependency>`.
4. Enable it with an empty file `root/etc/s6-overlay/user-bundles.d/user/contents.d/<name>`. Don't
   use `s6-rc.d/user/contents.d/`: since s6-overlay 3.2.3.1 a service listed there never starts
   (fixed in `fe82957`).
5. Leave `run` as mode 644 in git. Both Dockerfiles `chmod +x` every `run*` under `s6-rc.d`.

## Gotchas

- Edit `linux-amd64.Dockerfile` and `linux-arm64.Dockerfile` together. The only difference is that
  arm64's builder also installs `build-base python3`. Keep the `# check=skip=InvalidDefaultArgInFrom`
  header in both.
- Changing the port means editing `ENV PORT=` / `WEBUI_PORTS=` in both Dockerfiles, the `!= "3000"`
  guard in `init-setup-app/run`, and `test_url` in `meta.json`.
- Human commits use Conventional Commits. `Modified: <file>` is the bot's format; don't copy it.
