#!/usr/bin/env bash
# Purpose: Update the NPM Malware Protection to the latest version

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd)"
REPO_DIR="$(cd "$SELF_DIR/.." > /dev/null && pwd)"
LOCAL_VERSION="$(cat "${REPO_DIR}/VERSION.txt")"
REMOTE_VERSION="$(git show "origin/${UPSTREAM_BRANCH:-$(git branch --show-current)}:VERSION.txt" 2> /dev/null || echo "N/A")"

if [[ "$(which safe-chain || echo)" == "" ]]; then
  echo "⊘  Could not find \`safe-chain\` binary of Aikido Safe-Chain on \`PATH\`." >&2
  exit 1
fi

INSTALLED_SAFE_CHAIN_VERSION="$(safe-chain --version | awk '{print $4}')"

source "$SELF_DIR/read-dot-env.sh"

if [[ " $* " != *" --force "* && "$LOCAL_VERSION" == "$REMOTE_VERSION" && "$INSTALLED_SAFE_CHAIN_VERSION" == "$SAFE_CHAIN_VERSION" ]]; then
  echo "✓  Skipped update, since both Aikido Safe-Chain and safe-chain-symlinks are already up-to-date."
  echo "   Use \`--force\` to enforce an update (e.g., to reinstall currently installed version of Aikido Safe-Chain)."

  exit 0
fi

pushd "$REPO_DIR >/dev/null"

echo "---"
echo

./scripts/uninstall.sh

echo
echo "---"
echo

echo Pulling latest from git
git pull

echo
echo "---"
echo

./scripts/install.sh

popd >/dev/null
