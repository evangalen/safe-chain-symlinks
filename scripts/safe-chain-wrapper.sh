#!/usr/bin/env bash
# Purpose: Internal script that wrap the `safe-chain` from `bin` directory of Aikido Safe-Chain installation
#
# NOTE: instead of symlinks used to wrap the package managers, the `safe-chain` binary is wrapper by:
#        - the wrapper `safe-chain` shell function declared in the init-posix.sh shell script of safe-chain-symlinks
#        - explicitly executing this (wrapper) shell script from inside the package-manager-wrapper.sh shell script

set -euo pipefail

SELF="${BASH_SOURCE[0]}"
ABSOLUTE_SELF_DIR="$(cd "$(dirname "$SELF")" > /dev/null && pwd)"

VERSION="$(cat "$ABSOLUTE_SELF_DIR/../VERSION.txt")"

SAFE_CHAIN_BIN="$(which safe-chain || echo)"
if [[ "$SAFE_CHAIN_BIN" == "" ]]; then
  echo "⊘  Could not find \`safe-chain\` binary of Aikido Safe-Chain on \`PATH\`." >&2
  exit 1
fi

SAFE_CHAIN_INSTALL_DIR="$(dirname "$(dirname "$SAFE_CHAIN_BIN")")"
SAFE_CHAIN_SHIMS_DIR="$SAFE_CHAIN_INSTALL_DIR/shims"

# WORKAROUND: reuse earlier determined `INSTALLED_SAFE_CHAIN_VERSION` value to prevent following
#             `Error: Cannot find module '`..`/--version'` when `safe-chain-wrapper.sh` called recursively (e.g. `pip3`)
INSTALLED_SAFE_CHAIN_VERSION="${INSTALLED_SAFE_CHAIN_VERSION:-$(safe-chain --version 2>/dev/null | awk '{print $4}' || echo "N/A")}"

PACKAGE_MANAGERS_SPACE_SEPARATED="$($ABSOLUTE_SELF_DIR/list_package_managers.sh)"

PACKAGE_MANAGER=""

# when one or more CLI argument and first argument is a supported packaged manager ..
if [[ $# -ge 1 ]] && [[ " $PACKAGE_MANAGERS_SPACE_SEPARATED " == *" $1 "* ]]; then
  # .. then set `PACKAGE_MANAGER` and `PACKAGE_MANAGER_BIN_DIR` variables
  PACKAGE_MANAGER="$1"
  PACKAGE_MANAGER_BIN_DIR="$(dirname "$(which "$PACKAGE_MANAGER")")"

  # if actual bin is inside ..`-originals` dir (e.g., due to `python`/`python3` calling `pip`/`pip3` or vice versa) ..
  if [[ "$PACKAGE_MANAGER_BIN_DIR" == *"-originals" ]]; then
    # .. then correct actual bin
    PACKAGE_MANAGER_BIN_DIR="${PACKAGE_MANAGER_BIN_DIR%-originals}"
  fi
fi

# when:
#  - `safe-chain` is called with package manager argument
#  - and, the real, non CI/CD shim, package manager is on the `PATH`
#  - and, `safe-chain-verify` argument is "not" specified
#  - and `NO_SAFE_CHAIN_SYMLINKS_VERIFY` environment variable does "not" exist or "not" is true
if [[ "$PACKAGE_MANAGER" != "" && "$(which "$PACKAGE_MANAGER" || echo)" != "" && " $* " != *" safe-chain-verify "* && "${NO_SAFE_CHAIN_SYMLINKS_VERIFY:-false}" != "true" ]]; then
  SAFE_CHAIN_VERIFY_OUTPUT="$(mktemp)"
  SAFE_CHAIN_VERIFY_COMMAND=""$PACKAGE_MANAGER" safe-chain-verify"

  # execute the `safe-chain-verify` check and capture its output
  ${BASH_SOURCE[0]} "$PACKAGE_MANAGER" safe-chain-verify > "$SAFE_CHAIN_VERIFY_OUTPUT" 2>&1

  # when captured output contains the expected `OK: Safe-chain works!` message ..
  if grep -q "OK: Safe-chain works!" "$SAFE_CHAIN_VERIFY_OUTPUT"; then
    # .. then show a message that (auto) verify of safe-chain succeeded
    #    "unless" inside "non"-interactive terminal "or" when `--suppress-safe-chain-verify` CLI argument was provided
    if [[ -t 1 ]] && [[ " $* " != *" --suppress-safe-chain-verify "* ]]; then
      RESOLVED_PACKAGE_MANAGER_BIN="$(readlink "$PACKAGE_MANAGER_BIN_DIR/$PACKAGE_MANAGER" || echo)"
      WRAPPER="$ABSOLUTE_SELF_DIR/symlinked/package-manager-wrapper.sh"

      # when the (actual) package manager binary is "not" a symlink wrapper (yet) ..
      if [[ "$RESOLVED_PACKAGE_MANAGER_BIN" != "$WRAPPER" && ! -d "$SAFE_CHAIN_SHIMS_DIR" ]]; then
        # .. then display a warning about terminal-only protection (due to lack of symlink wrapper)
        echo "⚠  safe-chain-symlinks: Terminal‑only protection — \`$PACKAGE_MANAGER\` is only protected inside the terminal by Aikido Safe‑Chain (version: $INSTALLED_SAFE_CHAIN_VERSION; symlinks: $VERSION)"
      else
        # .. else: show a success message
        echo "✓  safe-chain-symlinks: Verified \`$PACKAGE_MANAGER\` to be protected by Aikido Safe-Chain (version: $INSTALLED_SAFE_CHAIN_VERSION; symlinks: $VERSION)"
      fi
    fi
  else
    # .. else: show a failure message and exit
    echo "⊘  Failed \`$SAFE_CHAIN_VERIFY_COMMAND\` check (Aikido Safe-Chain version: $INSTALLED_SAFE_CHAIN_VERSION; symlinks: $VERSION)" >&2
    exit 1
  fi
fi


updateSafeChainWrappers() {
  "$ABSOLUTE_SELF_DIR/update-wrappers.sh"
}

# when standard output is "not" a pipe (e.g., "$(npm --version)", a package manager is specified (e.g., `npm`) and
# `safe-chain-verify` argument is not specified then ..
if [[ ! -d "$SAFE_CHAIN_SHIMS_DIR" ]] && [[ -t 1 ]] && [[ "$PACKAGE_MANAGER" != "" && " $* " != *" safe-chain-verify "* ]]; then
  # .. register a trap to that runs on exit of the shell script to update the symlink wrappers
  trap updateSafeChainWrappers EXIT INT TERM HUP
fi

# use a sub-shell to the registered `trap` is actually executed
(
  # Unset PKG_EXECPATH so the yao-pkg bootstrap inside the safe-chain binary doesn't
  # mistake argv[1] for a script path and try to resolve it against cwd.
  unset PKG_EXECPATH

  # WORKAROUND: pass-through `INSTALLED_SAFE_CHAIN_VERSION` so `safe-chain --version` does not have to be called again,
  #             to workaround `safe-chain --version` failing when it's called recursively
  SAFE_CHAIN_WRAPPER_ACTIVE_PACKAGE_MANAGER="$PACKAGE_MANAGER" INSTALLED_SAFE_CHAIN_VERSION="$INSTALLED_SAFE_CHAIN_VERSION" exec safe-chain "$@"
)
