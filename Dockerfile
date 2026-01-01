FROM docker.io/debian:oldstable-slim

ARG USER=git
ARG GITOLITE_PACKAGE_VERSION=3.6.12-1
ARG GITOLITE_HOME_PATH=/var/lib/gitolite
ENV SSHD_HOST_KEYS_DIR=/etc/ssh/host_keys
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --yes \
        git-annex \
        git \
        gitolite3=$GITOLITE_PACKAGE_VERSION \
        openssh-server \
        tini \
    && rm -rf /var/lib/apt/lists/* \
    && rm /etc/ssh/ssh_host_*_key* \
    && useradd --home-dir "$GITOLITE_HOME_PATH" --create-home "$USER" \
    && getent passwd "$USER" \
    && mkdir "$SSHD_HOST_KEYS_DIR" \
    && chown -c "$USER" "$SSHD_HOST_KEYS_DIR"
# TODO merge up
RUN sed --in-place '/ENABLE => \[/a \\n            '"'git-annex-shell ua'," \
        /usr/share/gitolite3/lib/Gitolite/Rc.pm
VOLUME $GITOLITE_HOME_PATH
VOLUME $SSHD_HOST_KEYS_DIR

COPY sshd_config /etc/ssh/sshd_config
EXPOSE 2200/tcp

ENV GITOLITE_INITIAL_ADMIN_NAME=admin
COPY entrypoint.sh /
ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]

USER $USER
CMD ["/usr/sbin/sshd", "-D", "-e"]

# https://github.com/opencontainers/image-spec/blob/v1.0.1/annotations.md
ARG REVISION=
LABEL org.opencontainers.image.title="gitolite with support for git-annex" \
    org.opencontainers.image.source="https://github.com/fphammerle/docker-gitolite" \
    org.opencontainers.image.revision="$REVISION"
