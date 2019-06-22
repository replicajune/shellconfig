#!/bin/sh

# download and install the latest rambox package
# quick and dirty, but it works !
rambox_update () {
  # define the package needed
  case ${_PKG_MGR} in
    apt)  PKG_TYPE="amd64.deb";
          PKG_INST_CMD="dpkg -i";
          PKG_INST_CMD_NOFAIL="apt-get -f install";
      ;;
    yum)  PKG_TYPE="x86_64.rpm";
          PKG_INST_CMD="yum install -y";
      ;;
    *) echo "sorry, not compatible" && return 1;;
  esac

  # get a list if available packages
  REPO='ramboxapp/community-edition'
  LATEST_RELEASES=$(
    curl "https://api.github.com/repos/${REPO}/releases/latest" 2> /dev/null |
    jq ".assets |.[] | .browser_download_url" |
    tr -d '"'
  )

  for URL in ${LATEST_RELEASES}; do
    # get the right URL
    if [ "${URL##*-}" = "${PKG_TYPE}" ]; then
      echo "downloading ..."
      wget "${URL}" --output-document="/tmp/${URL##*/}" --quiet
      # install using defined package manager & manage a dpkg fail
      echo "installing, or upgrading ..."
      # shellcheck disable=SC2086
      sudo ${PKG_INST_CMD} "/tmp/${URL##*/}" ||\
        sudo ${PKG_INST_CMD_NOFAIL-'true'} || return 2
      rm -f "/tmp/${URL##*/}"
      break
    fi
  done
}
