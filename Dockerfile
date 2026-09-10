# termy-box — unofficial community Docker packaging of NPC-Forge / TERMy
# Does not modify upstream source. See README for attribution and AGPL-3.0 notes.
#
# Security: runs as non-root user `termy`. TERMy can execute shell commands;
# do not mount host paths you cannot afford to lose, and do not run with
# --privileged or unnecessary capabilities.
#
# Pins live in versions.env — pass matching --build-arg values (compose/CI do this).

ARG DEBIAN_IMAGE=debian:bookworm-slim@sha256:88200866dfff7ea7f5cbcb6ec7c8a701889efe6fe859fe64d6990e4b07ea4171
ARG NPC_FORGE_REF=58d33328ffc9031f7b7a16fbfc10285ca773e8c3
ARG IMAGE_SOURCE=https://github.com/Onur45500/termy-box

# ---------------------------------------------------------------------------
# Builder: install NPC-Forge + TERMy as non-root (setup.sh refuses root)
# ---------------------------------------------------------------------------
FROM ${DEBIAN_IMAGE} AS builder

ARG NPC_FORGE_REF
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 \
        python3-venv \
        python3-pip \
        rsync \
        ca-certificates \
        espeak-ng \
        bash \
        tar \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --shell /bin/bash --uid 1000 termy

# Pre-fetched pinned archive from the build context (run scripts/fetch-upstream.sh first).
# Avoids relying on container SSL to GitHub (broken on some Docker Desktop hosts).
COPY .build/NPC-Forge-${NPC_FORGE_REF}.tar.gz /tmp/npc-forge.tar.gz

RUN mkdir -p /home/termy/NPC-Forge \
    && tar -xz -C /home/termy/NPC-Forge --strip-components=1 -f /tmp/npc-forge.tar.gz \
    && rm -f /tmp/npc-forge.tar.gz \
    && chown -R termy:termy /home/termy/NPC-Forge

USER termy
WORKDIR /home/termy/NPC-Forge

# PIP_TRUSTED_HOST is builder-only: some Docker Desktop hosts break container SSL
# to PyPI. The runtime image never runs pip.
ENV HOME=/home/termy \
    PATH=/home/termy/.local/bin:/usr/local/bin:/usr/bin:/bin \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_TRUSTED_HOST="pypi.org files.pythonhosted.org pypi.python.org"

# setup.sh refuses root; systemd is absent in containers (graceful fallback)
RUN chmod +x setup.sh \
    && ./setup.sh \
    && npc-forge install npcs/termy

# Build-time smoke test: piped stdin avoids the TTY/args quirk
RUN echo "how are you" | termy \
    || (echo "ERROR: build-time TERMy smoke test failed" >&2; exit 1)

# Drop the clone; installed tree lives under ~/.local
RUN rm -rf /home/termy/NPC-Forge

# ---------------------------------------------------------------------------
# Final image: runtime only
# ---------------------------------------------------------------------------
FROM ${DEBIAN_IMAGE}

ARG NPC_FORGE_REF
ARG IMAGE_SOURCE
ARG DEBIAN_FRONTEND=noninteractive

LABEL org.opencontainers.image.title="termy-box" \
      org.opencontainers.image.description="Unofficial community Docker packaging of NPC-Forge/TERMy (deterministic, LLM-free terminal assistant). Not affiliated with the upstream maintainer." \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.licenses="AGPL-3.0-only" \
      org.opencontainers.image.vendor="termy-box community packaging" \
      io.termy-box.upstream="https://github.com/gioblu/NPC-Forge" \
      io.termy-box.upstream.ref="${NPC_FORGE_REF}" \
      io.termy-box.unofficial="true"

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 \
        bash \
        ca-certificates \
        coreutils \
        findutils \
        grep \
        curl \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --shell /bin/bash --uid 1000 termy \
    && mkdir -p /dataset /home/termy/work /home/termy/scripts \
    && chown termy:termy /dataset /home/termy/work /home/termy/scripts

# Copy installed user tree (venv paths are absolute under /home/termy)
COPY --from=builder --chown=termy:termy /home/termy/.local /home/termy/.local

COPY --chown=termy:termy entrypoint.sh /home/termy/entrypoint.sh
COPY --chown=termy:termy scripts/healthcheck.sh /home/termy/scripts/healthcheck.sh
COPY --chown=termy:termy scripts/termy-safe.sh /home/termy/scripts/termy-safe.sh
COPY --chown=termy:termy scripts/termy_propose.py /home/termy/scripts/termy_propose.py

RUN chmod +x /home/termy/entrypoint.sh \
             /home/termy/scripts/healthcheck.sh \
             /home/termy/scripts/termy-safe.sh

USER termy
WORKDIR /home/termy/work

ENV HOME=/home/termy \
    PATH=/home/termy/.local/bin:/usr/local/bin:/usr/bin:/bin \
    FORGE_DIR=/home/termy/.local/share/npc-forge \
    NPC_FORGE_REF=${NPC_FORGE_REF} \
    TERMY_MODE=cli \
    TERMY_PROPOSE_ONLY=0

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD ["/home/termy/scripts/healthcheck.sh"]

ENTRYPOINT ["/home/termy/entrypoint.sh"]
