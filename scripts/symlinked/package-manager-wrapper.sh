#!/usr/bin/env bash
# Purpose: symlinked wrapper usage for a package manager that's supported by Aikido Safe-Chain

set -euo pipefail

SELF="${BASH_SOURCE[0]}"
ABSOLUTE_SELF_DIR="$(cd "$(dirname "$SELF")" > /dev/null && pwd)"
PACKAGE_MANAGER="$(basename "$SELF")"

RESOLVED_SELF="$(readlink "$SELF")"
RESOLVED_SCRIPTS_DIR="$(cd "$(dirname "$RESOLVED_SELF")/.." > /dev/null && pwd)"

SAFE_CHAIN_INSTALL_DIR="$HOME/.safe-chain"

if [[ ! -d "$SAFE_CHAIN_INSTALL_DIR" ]]; then
  echo "⊘  Could not find installation of Aikido Safe-Chain." >&2
  exit 1
fi

SAFE_CHAIN_SHIMS_DIR="$SAFE_CHAIN_INSTALL_DIR/shims"

if [[ -d "$SAFE_CHAIN_SHIMS_DIR" ]]; then
  # remove `shims` directory of CI/CD installation of Aikido Safe-Chain from `PATH`
  PATH="$(printf "%s" "$PATH" | tr ':' '\n' | grep -v "^${SAFE_CHAIN_SHIMS_DIR}$" | paste -sd: -)"
fi

PATH_PREFIX=""

# when `safe-chain` binary is "not" on `PATH` (e.g., when package manager wrapper is used from UI of JetBrains IDE) //
if [[ "$(which safe-chain || echo)" == "" && ! -d "$SAFE_CHAIN_SHIMS_DIR" ]]; then
  # .. then re-assign `PATH_PREFIX` variable so later the safe-chain bin directory can be prefixed to the `PATH`
  PATH_PREFIX="$SAFE_CHAIN_INSTALL_DIR/bin:"
fi

# when package manager wrapper was called by safe-chain via the safe-chain-wrapper.sh and package manager is the same ..
if [[ "${SAFE_CHAIN_WRAPPER_ACTIVE_PACKAGE_MANAGER:-}" == "$PACKAGE_MANAGER" ]]; then
  unset SAFE_CHAIN_WRAPPER_ACTIVE_PACKAGE_MANAGER

  if [[ ! -d "$SAFE_CHAIN_SHIMS_DIR" ]]; then
    PATH="${ABSOLUTE_SELF_DIR}-originals:$PATH"
  fi

  # .. then only execute the original (non-wrapped) package manager binary
  exec "$PACKAGE_MANAGER" "$@"
else
  unset SAFE_CHAIN_WRAPPER_ACTIVE_PACKAGE_MANAGER

  if [[ ! -d "$SAFE_CHAIN_SHIMS_DIR" ]]; then
    PATH="${PATH_PREFIX}$ABSOLUTE_SELF_DIR:${PATH}"
  fi

  # .. else: execute safe-chain-wrapper.sh for the package manager, causing safe-chain protection to also work for:
  #     - a package manager that's "not" directly called from the command-line
  #     - a package manager that's called via another package manager (e.g., `npm install` from inside a Python script)
  exec "$RESOLVED_SCRIPTS_DIR/safe-chain-wrapper.sh" "$PACKAGE_MANAGER" "$@"
fi
