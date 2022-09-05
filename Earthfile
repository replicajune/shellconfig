VERSION 0.6
FROM registry.opensuse.org/opensuse/tumbleweed:latest
WORKDIR /srv
COPY --dir . .
RUN zypper refresh &> /dev/null && zypper install -y ShellCheck findutils &> /dev/null

all:
  BUILD +lint

lint:
    RUN .ci/shellcheck.sh
