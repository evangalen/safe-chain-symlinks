#!/usr/bin/env bash
# Purpose: Uninstall wrappers and restore originals for NVM-managed Node versions

set -euo pipefail

SELF="${BASH_SOURCE[0]}"
ABSOLUTE_SELF_DIR="$(cd "$(dirname "$SELF")" > /dev/null && pwd)"

SAFE_CHAIN_INSTALL_DIR="$HOME/.safe-chain"
SAFE_CHAIN_UNINSTALL_SCRIPT="$SAFE_CHAIN_INSTALL_DIR/scripts/uninstall-safe-chain.sh"

if [[ ! -d "$SAFE_CHAIN_INSTALL_DIR" ]]; then
  echo "⊘  Could not find installation of Aikido Safe-Chain." >&2
  exit 1
fi


PACKAGE_MANAGERS=($($ABSOLUTE_SELF_DIR/list_package_managers.sh))


teardown_wrappers_for_nvm_managed_node_version() {
  local vdir="$1"
  local bin_dir="${vdir}/bin"
  local originals_dir="${vdir}/bin-originals"
  [[ -d "$originals_dir" ]] || { echo "⚠  No originals for $(basename "$vdir")"; return; }

  for t in "${PACKAGE_MANAGERS[@]}"; do
    local target="$bin_dir/$t"
    local source="$originals_dir/$t"

    if [[ -f "$source" ]]; then
      echo "⚒  Tearing down \`$t\` wrapper in $bin_dir"

      # Remove target symlink or file before moving
      if [[ -L "$target" || -f "$target" ]]; then
        rm -f "$target"
      fi

      mv -f "$source" "$target"
    fi
  done
}

remove_bash_zsh_rc_source-init-nvm-wrapper-sh-line() {
  local rc_file=$1
  local entry="source \"$ABSOLUTE_SELF_DIR/init-posix.sh\""

  if [[ -f "$rc_file" ]] && grep -Fxq "$entry" "$rc_file"; then
    echo
    echo "⚒  Removing \`$entry\` (including surplus surrounding empty lines) from $rc_file"

    local tmp_rc_file="${rc_file}.tmp"

    set +e
    # Regex matches the target and all surrounding empty lines.
    # Logic: If removed block had a visual gap (>2 newlines), preserve one blank line; otherwise collapse it completely.
    TARGET_ENTRY="$entry" perl -0777 -pe '
      s/(\n(?:[ \t]*\n)*)[ \t]*\Q$ENV{TARGET_ENTRY}\E[ \t]*((?:\n[ \t]*)*\n)/
        length($1.$2) > 2 ? "\n\n" : "\n"
      /e' "$rc_file" > "$tmp_rc_file" 2> /dev/null
    local exit_code=$?
    set -e

    if [[ $exit_code -eq 0 ]]; then
      mv "$tmp_rc_file" "$rc_file"

      echo "→  Please restart your terminal to apply the changes."
    else
      echo "⚠  Failed removing \`$entry\` (including surplus surrounding empty lines) from $rc_file"
      rm -f "$tmp_rc_file"
    fi
  fi
}


# ----------------------------------------------------------------------------------------------------------------------
# initialize the NODE_VERSION_DIRS array using list_node_version_dirs.sh shell script returning line-separated entries
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


echo "▶  Unstalling Aikido Safe-Chain including \"safe-chain-symlinks\" enhancements"


# ----------------------------------------------------------------------------------------------------------------------
# Tear down symlink wrappers in bin folders of every NVM-managed Node.js version
#
for vdir in "${NODE_VERSION_DIRS[@]}"; do
  NPM_CLI="$vdir/lib/node_modules/npm/bin/npm-cli.js"

  echo
  echo "⚒  Tearing down wrappers for NVM-managed Node $(echo "$vdir" | sed 's|.*/||')"
  teardown_wrappers_for_nvm_managed_node_version "$vdir"

  if [[ -e "$vdir/bin-originals" ]]; then
    echo "⚒  Removing $vdir/bin-originals directory"
    rm -rf $vdir/bin-originals
  fi
done


# ----------------------------------------------------------------------------------------------------------------------
# Tear down symlinked wrappers for `PATH` entries other than NVM-managed Node versions
#
WRAPPER="$ABSOLUTE_SELF_DIR/symlinked/package-manager-wrapper.sh"

echo
echo "⚒  Tearing down wrappers for \`PATH\` entries other than NVM-managed Node versions"
# iterate through all entries on the `PATH` environment variable and for each ..
for dir in ${PATH//:/ }; do
  ORIGINAL_BIN_DIR="${dir}-originals"

  if [[ " ${NODE_VERSION_DIRS[@]} " != *" $(dirname "$dir") "* && ! -e "$ORIGINAL_BIN_DIR" ]]; then
    continue
  fi

  for packageManager in "${PACKAGE_MANAGERS[@]}"; do
    ACTUAL_BIN_DIR="$dir"
    ACTUAL_BIN="$ACTUAL_BIN_DIR/$packageManager"
    RESOLVED_ACTUAL_BIN="$(readlink "$ACTUAL_BIN" || echo)"
    ORIGINAL_BIN="$ORIGINAL_BIN_DIR/$packageManager"

    if [[ "$RESOLVED_ACTUAL_BIN" == "$WRAPPER" ]] && [[ -e "$ORIGINAL_BIN" || -L "$ORIGINAL_BIN" ]]; then
      echo "⚒  Tearing down \`$packageManager\` wrapper in $ACTUAL_BIN_DIR"

      # Remove actual symlink or file before moving
      if [[ -L "$ACTUAL_BIN" || -f "$ACTUAL_BIN" ]]; then
        rm -f "$ACTUAL_BIN"
      fi

      mv -f "$ORIGINAL_BIN" "$ACTUAL_BIN"
    fi
  done

done

# ----------------------------------------------------------------------------------------------------------------------
# Tear down symlinked wrappers for all files in `shims` directory of CI/CD installation of Aikido Safe-Chain
#
SHIMS_DIR="$SAFE_CHAIN_INSTALL_DIR/shims"
ORIGINAL_SHIMS_DIR="${SHIMS_DIR}-originals"

if [[ -e "$ORIGINAL_SHIMS_DIR" ]]; then
  echo

  if find "$ORIGINAL_SHIMS_DIR" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
    echo "⚒  Tearing down wrappers for all files in \`shims\` directory of CI/CD installation of Aikido Safe-Chain"
    for packageManager in "${PACKAGE_MANAGERS[@]}"; do
      mv -f "$ORIGINAL_SHIMS_DIR/$packageManager" "$SHIMS_DIR"
    done
  fi

  echo "⚒  Removing $ORIGINAL_SHIMS_DIR directory"
  rmdir "$ORIGINAL_SHIMS_DIR"
fi


# ----------------------------------------------------------------------------------------------------------------------
# Unstalling Aikido Safe-Chain uses either safe-chain-uninstall.sh downloaded during installation or by just removing
# the installation directory
#
echo

if [[ -e "$SAFE_CHAIN_UNINSTALL_SCRIPT" ]]; then
  echo "⚒  Uninstalling Aikido Safe-Chain using uninstall script (stored during installation in $SAFE_CHAIN_UNINSTALL_SCRIPT)"
  echo
  "$SAFE_CHAIN_UNINSTALL_SCRIPT"
else
  echo "⚒  Uninstalling Aikido Safe-Chain by removing directory $SAFE_CHAIN_INSTALL_DIR"
  rm -rf "$SAFE_CHAIN_INSTALL_DIR"

  echo
  echo "→  Manual remove \`source $HOME/.safe-chain/scripts/init-posix.sh\` from ~/.bashrc and / or ~/.zshrc files!"
  echo
fi


# ----------------------------------------------------------------------------------------------------------------------
# remove `source "<safe-chain-symlinks-repo>/scripts/init-posix.sh"` lines from ~/.bashrc and / or ~/.zshrc
#
remove_bash_zsh_rc_source-init-nvm-wrapper-sh-line ~/.bashrc
remove_bash_zsh_rc_source-init-nvm-wrapper-sh-line ~/.zshrc


echo
echo "▣  Uninstallation completed."
