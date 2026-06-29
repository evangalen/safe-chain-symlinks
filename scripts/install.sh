#!/usr/bin/env bash
# Purpose: Install malware protection wrappers for NVM-managed Node versions only

set -euo pipefail

ABSOLUTE_SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd)"
VERSION="$(cat "$ABSOLUTE_SELF_DIR/../VERSION.txt")"

add_bash_zsh_rc_source-init-nvm-wrapper-sh-line() {
  local rc_file=$1
  local entry="source \"$ABSOLUTE_SELF_DIR/init-posix.sh\""

  if [[ -f "$rc_file" ]] && ! grep -Fxq "$entry" "$rc_file"; then
    echo
    echo "⚒  Adding \`$entry\` entry to $rc_file"
    echo >> $rc_file
    echo "$entry" >> $rc_file

    echo "→  Please restart your terminal to apply the changes."
  fi
}

echo "▶  Installing Aikido Safe-Chain including \"safe-chain-symlinks\" enhancements"
echo

# ----------------------------------------------------------------------------------------------------------------------
# Retrieve the NVM-managed Node version directories or fail when Node Version Manager not found
#
set +e
NODE_VERSION_DIRS=()
while IFS= read -r line; do
    NODE_VERSION_DIRS+=("$line")
done < <("$ABSOLUTE_SELF_DIR/list_node_version_dirs.sh" "$@")
STATUS="$?"
set -e

if [[ "$STATUS" != "0" ]]; then
  echo "⊘  Could not determine version directories of NVM-managed Node versions" >&2
  exit $STATUS
fi


# ----------------------------------------------------------------------------------------------------------------------
# Install Aikido Safe-Chain including download of `uninstall-safe-chain.sh` and storing it in ~/.safe-chain/scripts
#
"$ABSOLUTE_SELF_DIR/safe-chain-install.sh" "$@"


# ----------------------------------------------------------------------------------------------------------------------
# Setup symlinked wrapper for ~/.safe-chain/bin/safe-chain
#
SAFE_CHAIN_INSTALL_DIR="$HOME/.safe-chain"

INSTALLED_SAFE_CHAIN_VERSION="$("$SAFE_CHAIN_INSTALL_DIR/bin/safe-chain" --version | awk '{print $4}')"


# ----------------------------------------------------------------------------------------------------------------------
# Setup symlink wrappers in bin folders of every NVM-managed Node.js version
#
if [[ " $* " != *" --ci "* ]]; then
  if [[ ${#NODE_VERSION_DIRS[@]} -eq 0 ]]; then
    echo "⚠  No NVM-managed Node versions found. Protection will auto-install on future 'nvm install'."
  else
    for nodeVersionDir in "${NODE_VERSION_DIRS[@]}"; do
      echo
      echo "⚒  Setting up wrappers for NVM-managed Node $(echo "$nodeVersionDir" | sed 's|.*/||')"
      "$ABSOLUTE_SELF_DIR/update-wrappers.sh" "$nodeVersionDir/bin"
    done
  fi
fi


# ----------------------------------------------------------------------------------------------------------------------
# Setup symlinked wrappers for `PATH` entries other than NVM-managed Node versions
#
if [[ " $* " != *" --ci "* ]]; then
  echo
  echo "⚒  Setting up wrappers for \`PATH\` entries other than NVM-managed Node versions"
  # iterate through all entries on the `PATH` environment variable and for each ..
  for dir in ${PATH//:/ }; do
    if [[ " ${NODE_VERSION_DIRS[@]} " == *" $(dirname "$dir") "* ]]; then
      continue
    fi

    # .. update wrappers for only the $dir directory
    SHOW_INSUFFICIENT_ACCESS_RIGHTS_MESSAGE="true" "$ABSOLUTE_SELF_DIR/update-wrappers.sh" "$dir"
  done
fi


# ----------------------------------------------------------------------------------------------------------------------
# Setup symlinked wrappers for all files in `shims` directory of CI/CD installation of Aikido Safe-Chain
#
if [[ " $* " == *" --ci "* ]]; then
  PACKAGE_MANAGERS=($($ABSOLUTE_SELF_DIR/list_package_managers.sh))
  SAFE_CHAIN_SHIMS_DIR="$SAFE_CHAIN_INSTALL_DIR/shims"
  SAFE_CHAIN_ORIGINAL_SHIMS_DIR="${SAFE_CHAIN_SHIMS_DIR}-originals"

  echo

  if [[ ! -d "$SAFE_CHAIN_ORIGINAL_SHIMS_DIR" ]]; then
    echo "⚒  Creating $SAFE_CHAIN_ORIGINAL_SHIMS_DIR directory to keep originals of CI/CD shims"
    mkdir -p "$SAFE_CHAIN_ORIGINAL_SHIMS_DIR"
  fi

  echo "⚒  Setting up wrappers for all files in \`shims\` directory of CI/CD installation of Aikido Safe-Chain"
  for packageManager in "${PACKAGE_MANAGERS[@]}"; do
    mv "$SAFE_CHAIN_SHIMS_DIR/$packageManager" "$SAFE_CHAIN_ORIGINAL_SHIMS_DIR"
    ln -sf "$ABSOLUTE_SELF_DIR/symlinked/package-manager-wrapper.sh" "$SAFE_CHAIN_SHIMS_DIR/$packageManager"
  done
fi


# ----------------------------------------------------------------------------------------------------------------------
# Patch ~/.bashrc and ~/.zshrc files so `cdnvm` respectively `load-nvmrc` do nothing inside a "non"-interactive shell.
#
# This patch is necessary so ./scripts/init-posix.sh of Aikido Safe-Chain installation also adds a correct `PATH` entry
# when initial directory of terminal uses a "non"-default NVM-managed Node version causing Node Version Manager (NVM)
# (in case its "Deeper Shell Integration" is used) to display a message like `Now using node v24.14.1`.
#
if [[ -e ~/.bashrc ]]; then
  if ! awk '
    /^cdnvm[[:space:]]*\(\)[[:space:]]*{/ { in_fn=1 }
    in_fn && /if \[\[ ! -t 1 \]\]/ { found=1 }
    in_fn && /^}/ { in_fn=0 }
    END { exit !found }
  ' ~/.bashrc; then

    echo
    echo "⚒  Applying patch in ~/.bashrc file to \`cdnvm\` shell function so NVM behaviour of \`cd\` (change directory) is skipped inside \"non\"-interactive shells"

    TEMP_ZSHRC_FILE=$(mktemp)

    awk -v absoluteSelfDir="$ABSOLUTE_SELF_DIR" '
      /^cdnvm[[:space:]]*\(\)[[:space:]]*{/ { in_fn=1 }
      in_fn && /command cd/ {
          print
          print ""
          print "    # NOTE: the `if [[ ! -t 1 ]]; then`, `return`, and closing `fi` below were injected by the following shell script:"
          print "    #       " absoluteSelfDir "/install.sh"
          print "    if [[ ! -t 1 ]]; then"
          print "      return # skip `cd` (change directory) behaviour of Node Version Manager (NVM) inside \"non\"-interactive shells"
          print "    fi"
          print ""
          next
      }
      in_fn && /^}/ { in_fn=0 }
      { print }
    ' ~/.bashrc > "$TEMP_ZSHRC_FILE" && mv "$TEMP_ZSHRC_FILE" ~/.bashrc

    rm -f "$TEMP_ZSHRC_FILE"
  fi
fi

if [[ -e ~/.zshrc ]]; then
  if ! awk '
    /^load-nvmrc[[:space:]]*\(\)[[:space:]]*{/ { in_fn=1 }
    in_fn && /if \[\[ ! -t 1 \]\]/ { found=1 }
    in_fn && /^}/ { in_fn=0 }
    END { exit !found }
  ' ~/.zshrc; then

    echo
    echo "⚒  Applying patch in ~/.zshrc file to \`load-nvmrc\` shell function so NVM behaviour of \`cd\` (change directory) is skipped inside \"non\"-interactive shells"

    TEMP_ZSHRC_FILE=$(mktemp)

    awk -v absoluteSelfDir="$ABSOLUTE_SELF_DIR" '
      /^load-nvmrc[[:space:]]*\(\)[[:space:]]*{/ { in_fn=1 }
      in_fn {
          print
          print "  # NOTE: the `if [[ ! -t 1 ]]; then`, `return`, and closing `fi` below were injected by the following shell script:"
          print "  #       " absoluteSelfDir "/install.sh"
          print "  if [[ ! -t 1 ]]; then"
          print "    return # skip `cd` (change directory) behaviour of Node Version Manager (NVM) inside \"non\"-interactive shells"
          print "  fi"
          print ""
          { in_fn=0 }
          next
      }
      { print }
    ' ~/.zshrc > "$TEMP_ZSHRC_FILE" && mv "$TEMP_ZSHRC_FILE" ~/.zshrc

    rm -f "$TEMP_ZSHRC_FILE"
  fi
fi


if [[ " $* " != *" --ci "* ]]; then
  add_bash_zsh_rc_source-init-nvm-wrapper-sh-line ~/.bashrc
  add_bash_zsh_rc_source-init-nvm-wrapper-sh-line ~/.zshrc
fi

echo
echo "▣  Installation completed of Aikido Safe-Chain $INSTALLED_SAFE_CHAIN_VERSION including \"safe-chain-symlinks\" enhancements (version: $VERSION)"
