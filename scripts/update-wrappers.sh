#!/usr/bin/env bash

set -euo pipefail

ABSOLUTE_SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd)"

SAFE_CHAIN_INSTALL_DIR="$HOME/.safe-chain"

if [[ ! -d "$SAFE_CHAIN_INSTALL_DIR" ]]; then
  echo "⊘  Could not find installation of Aikido Safe-Chain." >&2
  exit 1
fi

SAFE_CHAIN_SHIMS_DIR="$SAFE_CHAIN_INSTALL_DIR/shims"

if [[ -d "$SAFE_CHAIN_SHIMS_DIR" ]]; then
  # do nothing for a CI/CD installation of Aikido Safe-Chain
  exit 0
fi

PACKAGE_MANAGERS=($("$ABSOLUTE_SELF_DIR/list_package_managers.sh"))

FOCUSSED_BIN_DIR="${1:-}"

# when `$FOCUSSED_BIN_DIR` is any empty string ..
if [[ -z "$FOCUSSED_BIN_DIR" ]]; then
  # .. and `brew` is installed
  if type -f "brew" > /dev/null 2>&1; then
    BREW_BIN="$(brew --prefix)/bin"

    # ... then (locally) update the `PATH` to remove Brew `bin` directory
    PATH="$(printf "%s" "$PATH" | tr ':' '\n' | grep -v "^${BREW_BIN}$" | paste -sd: -)"
  fi
fi

# iterate through all the package managers supported by Aikido Safe-Chain
for packageManager in "${PACKAGE_MANAGERS[@]}"; do
  if [[ -n "$FOCUSSED_BIN_DIR" ]]; then
    ACTUAL_BIN="$FOCUSSED_BIN_DIR/$packageManager"
    ORIGINAL_BIN_DIR="$FOCUSSED_BIN_DIR-originals"
    ORIGINAL_BIN="$ORIGINAL_BIN_DIR/$packageManager"
  else
    ACTUAL_BIN="$(which "$packageManager" || echo)"

    if [[ "$ACTUAL_BIN" == "" ]]; then
      continue
    fi

    # if actual bin is inside ..`-originals` dir (e.g., due to `python`/`python3` calling `pip`/`pip3` or vice versa) ..
    if [[ "$(dirname "$ACTUAL_BIN")" == *"-originals" ]]; then
      ACTUAL_BIN_DIR="$(dirname "$ACTUAL_BIN")"

      # .. then correct actual bin
      ACTUAL_BIN="${ACTUAL_BIN_DIR%-originals}/$(basename "$ACTUAL_BIN")"
    fi

    ORIGINAL_BIN_DIR="$(dirname "$ACTUAL_BIN")-originals"
    ORIGINAL_BIN="$ORIGINAL_BIN_DIR/$packageManager"
  fi

  ACTUAL_BIN_DIR="$(dirname "$ACTUAL_BIN")"
  RESOLVED_ACTUAL_BIN="$(readlink "$ACTUAL_BIN" || echo)"

  WRAPPER="$ABSOLUTE_SELF_DIR/symlinked/package-manager-wrapper.sh"

  # if actual bin is an "absolute" symlink to the binary in the actual bin directory (e.g., `bunx` symlinks to `bun`) ..
  if [[ -L "$ACTUAL_BIN" && "$RESOLVED_ACTUAL_BIN" == "$ACTUAL_BIN_DIR/"* ]]; then
    SYMLINKED_OTHER_BIN_IN_ACTUAL_BIN_DIR="${RESOLVED_ACTUAL_BIN#"$ACTUAL_BIN_DIR/"}"

    # .. and the symlink target is also a package manager supported by safe-chain
    if [[ " ${PACKAGE_MANAGERS[@]} " == *" $SYMLINKED_OTHER_BIN_IN_ACTUAL_BIN_DIR "* ]]; then
      echo "⚒  safe-chain-symlinks: Changing \`$packageManager\` binary to use relative symlink to \`$SYMLINKED_OTHER_BIN_IN_ACTUAL_BIN_DIR\` instead of original symlinked $RESOLVED_ACTUAL_BIN"
      # .. then change absolute symlink to a relative symlink
      ln -sf "./$SYMLINKED_OTHER_BIN_IN_ACTUAL_BIN_DIR" "$ACTUAL_BIN"
    fi
  fi

  # when:
  #  - actual bin is a symlink
  #  - that resolves to a filename in `ACTUAL_BIN_DIR` (since it does "not" start with `.` and it does "not" have a `/`)
  #  - and, the filename is "not" one of the entries of the PACKAGE_MANAGERS array
  if [[ -L "$ACTUAL_BIN" && "$RESOLVED_ACTUAL_BIN" != "."* && "$RESOLVED_ACTUAL_BIN" != *"/"* && " ${PACKAGE_MANAGERS[@]} " != *" $RESOLVED_ACTUAL_BIN "* ]]; then
    # .. then change the (relative) filename symlink into an absolute symlink
    echo "⚒  safe-chain-symlinks: Changing \`$packageManager\` binary to use absolute symlink to \`$RESOLVED_ACTUAL_BIN\` instead of the original filename only symlink"
    ln -sf "$ACTUAL_BIN_DIR/$RESOLVED_ACTUAL_BIN" "$ACTUAL_BIN"
  fi

  # when actual bin is a (symlinked) wrapper, but original bin is a broken symlink (e.g., due to `brew uninstall`) ..
  if [[ "$RESOLVED_ACTUAL_BIN" == "$WRAPPER" && -L "$ORIGINAL_BIN" && ! -e "$ORIGINAL_BIN" ]]; then
    ACTUAL_BIN_DIR="$(dirname "$ACTUAL_BIN")"

    # .. then remove both the actual bin and the original bin, to ensure a future (brew) (re-)install works as expected
    echo "⚒  safe-chain-symlinks: Tearing down \`$packageManager\` wrapper in $ACTUAL_BIN_DIR due to broken symlink in $ORIGINAL_BIN_DIR"
    rm -f "$ACTUAL_BIN"
    rm -f "$ORIGINAL_BIN"

  # when the actual bin exists and it's not a (symlinked) wrapper then ..
  elif [[ -e "$ACTUAL_BIN" && "$RESOLVED_ACTUAL_BIN" != "$WRAPPER" ]]; then
    # when actual bin directory is not writeable (e.g. OS wide installs of python, python3, pip3, pip and pipx) ..
    if [[ ! -w "$ACTUAL_BIN_DIR" ]]; then
      # .. then (1) when `SHOW_INSUFFICIENT_ACCESS_RIGHTS_MESSAGE` environment variable is `true`
      if [[ "${SHOW_INSUFFICIENT_ACCESS_RIGHTS_MESSAGE:-false}" == "true" ]]; then
        echo "⚠  safe-chain-symlinks: Failed to setup \`$packageManager\` wrapper in $ACTUAL_BIN_DIR due to insufficient access rights"
      fi

      # .. then (2) skip creating a symlink wrapper (which otherwise would fail due to insufficient access rights)
      continue
    fi

    # .. then create a directory for the original bin if its does not exists already
    if [[ ! -d "$ORIGINAL_BIN_DIR" ]]; then
      echo "⚒  safe-chain-symlinks: Creating $ORIGINAL_BIN_DIR directory to keep originals of wrapped binaries"
      mkdir -p "$ORIGINAL_BIN_DIR"
    fi

    # .. then keep the actual bin as a original bin in a separate directory for bin originals
    echo "⚒  safe-chain-symlinks: Setting up \`$packageManager\` wrapper in $ACTUAL_BIN_DIR (keeping original binary in $ORIGINAL_BIN_DIR)"
    if [[ -e "$ORIGINAL_BIN" ]]; then
      rm -f "$ORIGINAL_BIN"
    fi
    mv "$ACTUAL_BIN" "$ORIGINAL_BIN_DIR"
    ln -sf "$ABSOLUTE_SELF_DIR/symlinked/package-manager-wrapper.sh" "$ACTUAL_BIN"
  fi
done
