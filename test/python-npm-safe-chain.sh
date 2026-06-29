if ! type curl | grep -E "curl is a (shell )?function" > /dev/null; then
  echo "⊘  Please use \`source\` to execute this shell script:" >&2
  echo "source $0" >&2
  exit 1
fi

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

SELF_DIR="$(dirname "$SELF")"

if command -v python >/dev/null 2>&1 && python -V >/dev/null 2>&1; then
    PYTHON_BIN="python"
else
    PYTHON_BIN="python3"
fi

echo "Executing: $PYTHON_BIN ./python-npm-safe-chain.py"
$PYTHON_BIN "$SELF_DIR/python-npm-safe-chain.py"
