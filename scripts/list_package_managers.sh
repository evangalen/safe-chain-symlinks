#!/usr/bin/env bash
# Purpose: Internal script used to output the names of package managers that are supported by Aikido Safe-Chain as
#          a space separated string (that's easily convertable into a Bash array)

set -euo pipefail

SAFE_CHAIN_INSTALL_DIR="$HOME/.safe-chain"

if [[ ! -d "$SAFE_CHAIN_INSTALL_DIR" ]]; then
  echo "⊘  Could not find installation of Aikido Safe-Chain." >&2
  exit 1
fi

# when Aikido Safe-Chain was installed for CI/CD usage ..
if [[ -d "$SAFE_CHAIN_INSTALL_DIR/shims" ]]; then
  # .. then return a space separated string with all the file in the $SAFE_CHAIN_INSTALL_DIR/shims directory
  echo "$(cd "$SAFE_CHAIN_INSTALL_DIR/shims" && printf "%s " *)"
  exit 0
fi

# otherwise use `awk` to extract supported package managers from `init-posix.sh` file of Aikido Safe-Chain installation
awk '
  # Match: function name() {
  /^[[:space:]]*function[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(/ {
      fn = $2
      sub(/\(.*/, "", fn)
      in_fn = 1
      body = ""
  }

  # Match: name() {
  /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(\)[[:space:]]*\{/ {
      fn = $1
      sub(/\(.*/, "", fn)
      in_fn = 1
      body = ""
  }

  # Accumulate body until closing brace
  in_fn {
      body = body $0 "\n"
      if ($0 ~ /\}/) {
          if (fn != "wrapSafeChainCommand" && body ~ /wrapSafeChainCommand/) {
              funcs = funcs " " fn
          }
          in_fn = 0
      }
  }

  END {
      sub(/^ /, "", funcs)
      print funcs
  }
' "$HOME/.safe-chain/scripts/init-posix.sh"
