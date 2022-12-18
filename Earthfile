VERSION 0.6
FROM registry.opensuse.org/opensuse/tumbleweed:latest
WORKDIR /srv
COPY --dir . .
RUN zypper refresh &> /dev/null && zypper install -y ShellCheck findutils &> /dev/null

all:
  BUILD +lint
  BUILD +testing

run-all:
  BUILD +run-alpine
  BUILD +run-ubuntu
  BUILD +run-debian
  BUILD +run-rocky
  BUILD +run-opensuse
  BUILD +run-fedora

run-alpine:
  BUILD +run --image=alpine --version=3.17
run-ubuntu:
  BUILD +run --image=ubuntu --version=22.10
run-debian:
  BUILD +run --image=debian --version=11
run-rocky:
  BUILD +run --image=rockylinux --version=9
run-opensuse:
  BUILD +run --reg_path=registry.opensuse.org/opensuse --image=tumbleweed --version=latest
run-fedora:
  BUILD +run --reg_path=registry.fedoraproject.org --image=fedora-minimal --version=34

lint:
    RUN .ci/shellcheck.sh

run:
  ARG image
  ARG version
  ARG reg_path=docker.io/library
  FROM $reg_path/$image:$version
  WORKDIR /root
  COPY --dir . .shellconfig
  RUN sh -ic ". .shellconfig/shellconfig.sh"
