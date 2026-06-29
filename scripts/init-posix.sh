# NOTE: this shell script deliberately does "not" use a hash bash (e.g., `#! /bin/sh`) or she bang
#       (e.g., `#!/usr/bin/env bash`) since it's intended to be `source`-d from the ~/.bashrc and / or ~/.zshrc file.

# Purpose: This `./scripts/init-posix.sh` shell script augments the `~/.safe-chain/scripts/init-posix.sh` shell script
#          from the installed Aikido Safe-Chain, to automatically setup (add) and (in some situations) teardown (remove)
#          symlink wrappers for package managers (e.g., `npm`).
#
#          These symlink wrappers complement the shell script based wrappers from Aikido Safe-Chain to give a more
#          watertight malware protection that also works outside the terminal, giving a symlink wrapper is available.


# ----------------------------------------------------------------------------------------------------------------------
# Determine `SELF_FILENAME` and `ABSOLUTE_SELF_DIR` in a way compatible with both Bash and Zsh
#
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  SELF="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  # WORKAROUND: Zsh only expands the (%):-%x prompt escape when re‑evaluated,
  #             so we must use eval to obtain the sourced file's path.
  eval 'SELF="${(%):-%x}"'
else
  echo "⊘  Only Bash or Zsh is supported by \"safe-chain-symlinks\" !" >&2
  exit 1
fi

SELF_FILENAME="$(basename "$SELF")"
ABSOLUTE_SELF_DIR="$(cd "$(dirname "$SELF")" > /dev/null && pwd)"


# ----------------------------------------------------------------------------------------------------------------------
# Extend `PATH` with ./bin directory (containing the `safe-chain-symlinks` binary)
#
ABSOLUTE_BIN_DIR="$(cd "$ABSOLUTE_SELF_DIR/../bin" > /dev/null && pwd)"

export PATH="$ABSOLUTE_BIN_DIR:$PATH"


# ----------------------------------------------------------------------------------------------------------------------
# Wrap `safe-chain` binary with a shell function executing safe-chain-wrapper.sh to do the actual wrapping of safe-chain
#
safe-chain() {
  command "$ABSOLUTE_SELF_DIR/safe-chain-wrapper.sh" "$@"
  return $?
}


# ----------------------------------------------------------------------------------------------------------------------
# Declare `updateSafeChainWrappers` function that call the ./update-wrappers.sh shell script
#
updateSafeChainWrappers() {
  local focussedBinDir=${1:-}

  "$ABSOLUTE_SELF_DIR/update-wrappers.sh" "$focussedBinDir"
}


# ----------------------------------------------------------------------------------------------------------------------
# Wrap `nvm` shell function to execute `updateSafeChainWrappers "$node_bin_dir"` after each `nvm`.. command
#
if typeset -f nvm >/dev/null 2>&1; then
  # capture source-code of `nvm` shell function and rename function to `nvmOriginal`
  NVM_ORIGINAL_FN_STRING=$(printf "%s\n" "$(declare -f nvm)" | sed '1s/nvm/nvmOriginal/')

  # remove original `nvm` shell function
  if [ -n "${BASH_SOURCE[0]:-}" ]; then
      unset -f nvm
  else
      unfunction nvm 2>/dev/null
  fi

  eval "$NVM_ORIGINAL_FN_STRING"

  nvm() {
    nvmOriginal "$@"

    local node_path="$(which node)"

    if [[ "$node_path" != "" ]]; then
      local node_bin_dir="$(dirname "$node_path")"

      updateSafeChainWrappers "$node_bin_dir"
    fi
  }
else
  echo "⊘  Missing \`nvm\` shell function (of Node Version Manager)" >&2
fi


# ----------------------------------------------------------------------------------------------------------------------
# Declare `registerBeforePromptFunction` helper function
#
registerBeforePromptFunction() {
  local functionName="$1"

  if [ -n "${BASH_SOURCE[0]:-}" ]; then
    PROMPT_COMMAND="$functionName${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
  else
      # Ensure precmd_functions array exists
      typeset -ga precmd_functions

      precmd_functions+=($functionName)
  fi
}


# ----------------------------------------------------------------------------------------------------------------------
# Automatically update the safe-chain symlink wrappers when terminal prompt is about to be shown:
#  - for the first time in a newly opened terminal
#  - when the `PATH` was changed since last time; e.g. due to a `source` of a shell script like `source ~/.bashrc`
#
PREVIOUS_PATH=""

updateSafeChainWrappersBeforePrompt() {
  if [[ "$PREVIOUS_PATH" == "" ]] || [[ "$PREVIOUS_PATH" != "" && "$PATH" != "$PREVIOUS_PATH" ]]; then
    updateSafeChainWrappers
  fi

  PREVIOUS_PATH="$PATH"
}

registerBeforePromptFunction updateSafeChainWrappersBeforePrompt


# ----------------------------------------------------------------------------------------------------------------------
# Wrap `brew` with a shell function to update the safe-chain symlink wrappers after executing every `brew `.. command
#
brew() {
  if ! type -f "brew" > /dev/null 2>&1; then
    # If the original command is not available, don't try to wrap it: invoke it transparently,
    # so the shell can report errors as if this wrapper didn't exist.
    command brew "$@"
    return $?
  fi

  local brewPrefix="$(command brew --prefix)"

  command brew "$@"

  updateSafeChainWrappers "$brewPrefix/bin"
}


# ----------------------------------------------------------------------------------------------------------------------
# Wrap `curl` with a shell function that injects a shell `trap` to automatically update the safe-chain symlink wrappers
# when a shell installation script of known install URLs for package managers (supported by safe-chain) are executed
#
curl() {
  local installShellScriptUrls=(
    "https://get.pnpm.io/install.sh"          # https://pnpm.io/installation#on-posix-systems
    "https://bun.sh/install"                  # https://bun.sh/
    "https://bun.com/install"                 # https://bun.com/docs/installation#installation
    "https://astral.sh/uv/install.sh"         # https://docs.astral.sh/uv/#installation
    "https://astral.sh/uv/*/install.sh"       # https://docs.astral.sh/uv/getting-started/installation
    "https://pdm-project.org/install.sh"      # https://pdm-project.org/en/latest/#recommended-installation-method
  )

  local foundInstallShellScriptUrl=""

  for curlArgument in "$@"; do
    for url in "${installShellScriptUrls[@]}"; do
      if [[ $curlArgument == $url ]]; then
        foundInstallShellScriptUrl="$curlArgument"
        break
      fi
    done
  done

  # execute curl normally when none of the known install shell script URLs were used in its arguments
  if [[ -z "$foundInstallShellScriptUrl" ]]; then
    command curl "$@"
    return $?
  fi

  tempCurlOutput="$(mktemp)"

  # otherwise: execute curl command and capture its output in a temporary file
  command curl "$@" > "$tempCurlOutput"
  exitCode=$?

  # when the curl command failed
  if [[ "$exitCode" != "0" ]]; then
    # .. then just output the captured output
    cat "$tempCurlOutput"
  else
    # .. else: inject a` trap` that executes the update-wrappers.sh shell script on exit
    head -n 1 "$tempCurlOutput"
    echo
    echo "# NOTE: the \`trap \"$ABSOLUTE_SELF_DIR/update-wrappers.sh\" EXIT INT TERM HUP;\`,"
    echo "#       the opening \`(\` bracket below, and the matching closing \`)\` bracket at the end in output of"
    echo "#       \`curl "$@"\`"
    echo "#       were injected by the \`curl\` wrapper shell function located in following shell script:"
    echo "#       $ABSOLUTE_SELF_DIR/$SELF_FILENAME"
    echo "trap \"$ABSOLUTE_SELF_DIR/update-wrappers.sh\" EXIT INT TERM HUP;"
    echo "("
    tail -n +2 "$tempCurlOutput"
    echo ")"
  fi

  rm -f "$tempCurlOutput"

  return $exitCode
}
