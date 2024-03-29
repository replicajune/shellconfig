#!/usr/bin/env bash
set -eu -o pipefail
ERROR=0

# Custom ShellCheck. one script triggered by two different CI (Earthly for local tests, github actions for origin tests)
while IFS= read -r -d '' SHFILE; do
  if ! head -1 "${SHFILE}" | grep -Fq '#!/usr/bin/env zsh'; then
    shellcheck --external-sources --format=gcc --color=always \
      --exclude=SC1090,SC2039,SC3037,SC3043,SC1091,SC3003 "${SHFILE}" \
    || ERROR=1
  fi
done < <(find . -name "*.sh" -type f -print0)

if [ "${ERROR}" = '1' ]; then exit 1; fi

# SC1090: https://github.com/koalaman/shellcheck/wiki/SC1090
# - most tests in a CI job would miss the location of an expected
#   file on target
# SC2039,SC3037,SC3043,SC3003 : https://github.com/koalaman/shellcheck/wiki/SC2039
# - using "local", echo flags, ect.. works on at least alpine and
#   openwrt, if busybox is safe, this is enough for me.
