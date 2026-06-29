if ! type curl | grep -E "curl is a (shell )?function" > /dev/null; then
  echo "⊘  Please use \`source\` to execute this shell script:" >&2
  echo "source $0" >&2
  exit 1
fi

# TODO: remove `# pnpm` .. `# pnpm end` section from both `.bashrc` and `.zshrc`

if [[ "${PNPM_HOME:-}" == "" ]]; then
  echo "⊘  Missing PNPM_HOME environment variable!" >&2
else
  if [[ -e "$PNPM_HOME" ]]; then
    echo "⚒  Removing the global content-addressable store"
    rm -rf "$($PNPM_HOME/bin/pnpm store path)"

    echo "⚒  Removing $PNPM_HOME directory"
    rm -rf "$PNPM_HOME"
  else
    echo "⊘  No $PNPM_HOME directory exists!" >&2
  fi
fi
