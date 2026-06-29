#!/usr/bin/env bash
# Purpose: Internal shell script used to install Aikido Safe-Chain and check downloaded version with the expected hash

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd)"

source "$SELF_DIR/read-dot-env.sh"

SAFE_CHAIN_INSTALL_DIR="$HOME/.safe-chain"

# Download install script
INSTALL_SAFE_CHAIN_SH_TEMP=$(mktemp)

echo "⚒  Downloading install script for Aikido Safe-Chain (compatible with legacy Node versions)"
set +e
curl -fsSL "https://github.com/AikidoSec/safe-chain/releases/download/$SAFE_CHAIN_VERSION/install-safe-chain.sh" -o "$INSTALL_SAFE_CHAIN_SH_TEMP"
STATUS="$?"
set -e

if [[ "$STATUS" != "0" ]]; then
  echo "⊘  Download of install script for Aikido Safe-Chain failed" >&2
  rm "$INSTALL_SAFE_CHAIN_SH_TEMP"
  exit $STATUS
fi

ACTUAL_INSTALL_SAFE_CHAIN_DOT_SH_HASH="$(cat "$INSTALL_SAFE_CHAIN_SH_TEMP" | (command -v sha256sum >/dev/null && sha256sum || shasum -a 256) | awk '{print $1}')"


# Download uninstall script of Aikido Safe-Chain
UNINSTALL_SAFE_CHAIN_SH_TEMP=$(mktemp)

echo "⚒  Downloading uninstall script for Aikido Safe-Chain (compatible with legacy Node versions)"
set +e
curl -fsSL "https://github.com/AikidoSec/safe-chain/releases/download/$SAFE_CHAIN_VERSION/uninstall-safe-chain.sh" -o "$UNINSTALL_SAFE_CHAIN_SH_TEMP"
STATUS="$?"
set -e

if [[ "$STATUS" != "0" ]]; then
  echo "⊘  Download of uninstall script for Aikido Safe-Chain failed" >&2
  rm "$UNINSTALL_SAFE_CHAIN_SH_TEMP"
  exit $STATUS
fi

ACTUAL_UNINSTALL_SAFE_CHAIN_DOT_SH_HASH="$(cat "$UNINSTALL_SAFE_CHAIN_SH_TEMP" | (command -v sha256sum >/dev/null && sha256sum || shasum -a 256) | awk '{print $1}')"

# Checking hashes of downloaded install and uninstall scripts
if [ "$INSTALL_SAFE_CHAIN_DOT_SH_HASH" != "$ACTUAL_INSTALL_SAFE_CHAIN_DOT_SH_HASH" ]; then
  echo "⊘  Actual hash of downloaded install script for Aikido Safe-Chain differs from expected hash." >&2
  echo "$INSTALL_SAFE_CHAIN_DOT_SH_HASH $ACTUAL_INSTALL_SAFE_CHAIN_DOT_SH_HASH"
  rm "$INSTALL_SAFE_CHAIN_SH_TEMP"
  exit 1
fi

if [ "$UNINSTALL_SAFE_CHAIN_DOT_SH_HASH" != "$ACTUAL_UNINSTALL_SAFE_CHAIN_DOT_SH_HASH" ]; then
  echo "⊘  Actual hash of downloaded install script for Aikido Safe-Chain differs from expected hash." >&2
  rm "$UNINSTALL_SAFE_CHAIN_SH_TEMP"
  exit 1
fi


# Remove and old uninstall script, uninstall-safe-chain.sh file, from Aikido Safe-Chain installation
if [[ -f "$SAFE_CHAIN_INSTALL_DIR/scripts/uninstall-safe-chain.sh" ]]; then
  echo "⚒  Removing existing uninstall-safe-chain.sh file from earlier installation"
  rm -f "$SAFE_CHAIN_INSTALL_DIR/scripts/uninstall-safe-chain.sh"
fi


# Execute downloaded (temporary) install script of Aikido Safe-Chain and finally remove temporary install script
echo "⚒  Executing downloaded install script for Aikido Safe-Chain"
echo
set +e
if [[ " $* " != *" --ci "* ]]; then
  cat "$INSTALL_SAFE_CHAIN_SH_TEMP" | sh -
else
  cat "$INSTALL_SAFE_CHAIN_SH_TEMP" | sh -s -- --ci
fi
STATUS="$?"
set -e

if [[ "$STATUS" != "0" ]]; then
  echo "⊘  Failed to execute downloaded install script for Aikido Safe-Chain" >&2
  rm "$INSTALL_SAFE_CHAIN_SH_TEMP"
  exit $STATUS
fi

if [[ ! -d "$SAFE_CHAIN_INSTALL_DIR/scripts" ]]; then
  echo
  echo "⚒  Creating $SAFE_CHAIN_INSTALL_DIR/scripts directory to keep downloaded \`uninstall-safe-chain.sh\`"
  mkdir "$SAFE_CHAIN_INSTALL_DIR/scripts"
fi

# Move downloaded uninstall script, uninstall-safe-chain.sh file, to Aikido Safe-Chain installation
echo
echo "⚒  Moving downloaded \`uninstall-safe-chain.sh\` to $SAFE_CHAIN_INSTALL_DIR/scripts"
echo "# NOTE: this uninstall-safe-chain.sh file was downloaded by ./scripts/install-safe-chain.sh from the following URL:" > "$SAFE_CHAIN_INSTALL_DIR/scripts/uninstall-safe-chain.sh"
echo "#       https://github.com/AikidoSec/safe-chain/releases/download/$SAFE_CHAIN_VERSION/uninstall-safe-chain.sh" >> "$SAFE_CHAIN_INSTALL_DIR/scripts/uninstall-safe-chain.sh"
echo >> "$SAFE_CHAIN_INSTALL_DIR/scripts/uninstall-safe-chain.sh"
cat "$UNINSTALL_SAFE_CHAIN_SH_TEMP" >> "$SAFE_CHAIN_INSTALL_DIR/scripts/uninstall-safe-chain.sh"
chmod u+x "$SAFE_CHAIN_INSTALL_DIR/scripts/uninstall-safe-chain.sh"
rm "$UNINSTALL_SAFE_CHAIN_SH_TEMP"


# Remove temporary install script
rm "$INSTALL_SAFE_CHAIN_SH_TEMP"
