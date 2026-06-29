#!/usr/bin/env bash
# Purpose: Internal script, intended to be used with `source`, that reads settings of `.env` file in root of the repo
#          and then exposes them as (non-exported) environment variables named in all upper case and underscores

readDotEnv() {
  local selfDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd)"
  local repoRoot="$(cd "$selfDir/.." > /dev/null && pwd)"

  # Load .env file
  local envFile="$repoRoot/.env"

  if [[ ! -f "$envFile" ]]; then
    echo "⊘  .env file not found in repository root: $envFile" >&2
    exit 1
  fi

  local key value # ensure that `key` and `value` are local variables by pre-declaring it

  # Read .env and convert dashed keys → underscored variable names
  while IFS='=' read -r key value; do
    # Skip comments and empty lines
    [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue

    # Convert dashes to underscores for Bash compatibility
    local safe_key="${key//-/_}"

    local "$safe_key" # ensure that "$safe_key" is a local variable by pre-declaring it

    # assign value read from .env file to variable with name read from $safe_key
    printf -v "$safe_key" '%s' "$value"
  done < "$envFile"

  # Validate required settings
  if [[ -z "${safe_chain_version:-}" ]]; then
    echo "⊘  Missing required setting: safe-chain-version in .env" >&2
    exit 1
  fi

  if [[ -z "${install_safe_chain_dot_sh_hash:-}" ]]; then
    echo "⊘  Missing required setting: install-safe-chain-dot-sh-hash in .env" >&2
    exit 1
  fi

  if [[ -z "${uninstall_safe_chain_dot_sh_hash:-}" ]]; then
    echo "⊘  Missing required setting: uninstall-safe-chain-dot-sh-hash in .env" >&2
    exit 1
  fi

  # Assign variables from .env (strip sha256: prefix)
  SAFE_CHAIN_VERSION="$safe_chain_version"
  INSTALL_SAFE_CHAIN_DOT_SH_HASH="${install_safe_chain_dot_sh_hash#sha256:}"
  UNINSTALL_SAFE_CHAIN_DOT_SH_HASH="${uninstall_safe_chain_dot_sh_hash#sha256:}"
}

readDotEnv

unset -f readDotEnv # unset `readDotEnv` shell function to keep things clean since read-dot-env.sh will be `source`-d
