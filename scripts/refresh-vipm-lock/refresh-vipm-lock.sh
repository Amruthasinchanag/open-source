#!/usr/bin/env bash
# Installs/activates VIPM, refreshes the repository cache, and generates or
# checks vipm.lock from vipm.toml. Executed inside the VIPM Linux container by
# RefreshVipmLock.ps1.
set -euo pipefail

WORKING_DIRECTORY=""
LABVIEW_VERSION=""
LABVIEW_BITNESS=""
CHECK_ONLY="false"
VIPM_DEB_URL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --working-directory) WORKING_DIRECTORY="$2"; shift 2 ;;
    --labview-version) LABVIEW_VERSION="$2"; shift 2 ;;
    --labview-bitness) LABVIEW_BITNESS="$2"; shift 2 ;;
    --check-only) CHECK_ONLY="$2"; shift 2 ;;
    --vipm-deb-url) VIPM_DEB_URL="$2"; shift 2 ;;
    *) echo "error: unknown argument '$1'" >&2; exit 2 ;;
  esac
done

apt-get update
apt-get install -y wget ca-certificates xvfb

if ! command -v vipm >/dev/null 2>&1; then
  wget -O /tmp/vipm.deb "${VIPM_DEB_URL}"
  apt-get install -y /tmp/vipm.deb
fi

export DISPLAY=:99
export VIPM_TIMEOUT=500
Xvfb "$DISPLAY" -screen 0 1280x720x24 -ac +extension GLX +render -noreset >/tmp/xvfb.log 2>&1 &

vipm --version

if [ -n "${VIPM_SERIAL_NUMBER:-}" ]; then
  vipm activate --serial-number "$VIPM_SERIAL_NUMBER" --name "$VIPM_FULL_NAME" --email "$VIPM_EMAIL"
fi

cd "$WORKING_DIRECTORY"

# Clean runner has no repository cache; populate it for this project's LabVIEW
# target before lock resolution (see docs.vipm.io/cli/command-reference#vipm-refresh).
vipm refresh --labview-version "$LABVIEW_VERSION" --labview-bitness "$LABVIEW_BITNESS"

if [ "$CHECK_ONLY" = "true" ]; then
  vipm lock --check
else
  vipm lock
fi
