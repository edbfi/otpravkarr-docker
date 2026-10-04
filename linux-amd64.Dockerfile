# syntax=docker/dockerfile:1
# check=skip=InvalidDefaultArgInFrom
ARG UPSTREAM_IMAGE
ARG UPSTREAM_TAG_SHA

FROM oven/bun:alpine AS builder
RUN apk add --no-cache curl
ARG VERSION
ENV COMMIT_TAG=${VERSION}
# bun install runs the root lifecycle scripts even with --production, and prepare needs dev
# dependencies (svelte-kit). Remove prepare and postinstall before the production install.
RUN mkdir /build && \
    curl -fsSL "https://github.com/edbfi/otpravkarr/archive/${VERSION}.tar.gz" | tar xzf - -C "/build" --strip-components=1 && \
    cd /build && \
    bun install --frozen-lockfile && \
    bun run build && \
    rm -rf node_modules && \
    bun -e 'const p = await Bun.file("package.json").json(); delete p.scripts.prepare; delete p.scripts.postinstall; await Bun.write("package.json", JSON.stringify(p));' && \
    bun install --production --frozen-lockfile


FROM ${UPSTREAM_IMAGE}:${UPSTREAM_TAG_SHA}
ARG IMAGE_STATS
ARG VERSION
# Docker stops a container after 10 s by default; the Hotio s6 teardown after the app exits
# takes about 3.3 s, so the app may drain requests for 5 s and still exit in time. Override
# with -e SHUTDOWN_TIMEOUT=<seconds> together with a longer stop timeout (docker stop -t).
ENV IMAGE_STATS=${IMAGE_STATS} PORT=3000 WEBUI_PORTS="3000/tcp,3000/udp" \
    NODE_ENV=production COMMIT_TAG=${VERSION} \
    SHUTDOWN_TIMEOUT=5
EXPOSE ${PORT}

COPY --from=builder /usr/local/bin/bun /usr/local/bin/bun
COPY --from=builder /build/build "${APP_DIR}/build"
COPY --from=builder /build/node_modules "${APP_DIR}/node_modules"
COPY --from=builder /build/package.json "${APP_DIR}/package.json"
COPY --from=builder /build/scripts/serve.ts "${APP_DIR}/scripts/serve.ts"

RUN mkdir -p "${CONFIG_DIR}/data" && \
    rm -rf "${APP_DIR}/data" && ln -s "${CONFIG_DIR}/data" "${APP_DIR}/data" && \
    chmod -R u=rwX,go=rX "${APP_DIR}"

COPY root/ /
RUN find /etc/s6-overlay/s6-rc.d -name "run*" -execdir chmod +x {} +
