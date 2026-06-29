#!/usr/bin/env bash
# Purpose: Internal script used to retrieve all the `bin` directories from all NVM-managed Node versions

set -euo pipefail

if [[ " $* " == *" --ci "* ]]; then
  exit
fi

load_nvm() {
  if [[ "${NVM_DIR:-}" == "" ]]; then
    echo "⊘  NVM_DIR environment variable not found. Install NVM from https://github.com/nvm-sh/nvm" >&2
    exit 1
  fi

  if command -v brew >/dev/null 2>&1; then
    BREW_PREFIX="$(brew --prefix)"

    if [[ -e "$BREW_PREFIX/opt/nvm/nvm.sh" ]]; then
      echo "⊘  NVM installed via Brew is not supported. Install NVM from https://github.com/nvm-sh/nvm" >&2
      exit 1
    fi
  fi

  source "${NVM_DIR}/nvm.sh"

  if [[ "$(type -t nvm)" != "function" ]]; then
    echo "⊘  NVM not loaded" >&2
    exit 1
  fi

  nvm deactivate >/dev/null 2>&1
  NON_NVM_NODE="$(which node || echo)"

  if [[ "$NON_NVM_NODE" != "" ]]; then
    echo "⊘  Non-NVM Node detected at: $NON_NVM_NODE" >&2
    exit 1
  fi

  source "${NVM_DIR}/nvm.sh"
}

list_nvm_node_version_dirs() {
  local base="${NVM_DIR}/versions/node"
  if [[ -d "$base" ]]; then
    while IFS= read -r d; do
      echo "$d"
    done < <(find "$base" -maxdepth 1 -mindepth 1 -type d | sort)
  fi
}


load_nvm
list_nvm_node_version_dirs
