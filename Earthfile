VERSION 0.6
FROM registry.opensuse.org/opensuse/tumbleweed:latest
WORKDIR /srv

lint:
    COPY --dir . .
    RUN zypper refresh &> /dev/null && zypper install -y ShellCheck findutils &> /dev/null
    RUN ls .ci/csc.sh
    RUN .ci/csc.sh
