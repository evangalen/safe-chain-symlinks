if ! type curl | grep -E "curl is a (shell )?function" > /dev/null; then
  echo "⊘  Please use \`source\` to execute this shell script:" >&2
  echo "source $0" >&2
  exit 1
fi

# TODO: remove `# bun` section from both `.bashrc` and `.zshrc`

if [[ "${BUN_INSTALL:-}" == "" ]]; then
  echo "⊘  Missing BUN_INSTALL environment variable!" >&2
else
  if [[ -e "$BUN_INSTALL" ]]; then
    echo "⚒  Removing $BUN_INSTALL directory"
    rm -rf "$BUN_INSTALL"
  else
    echo "⊘  No $BUN_INSTALL directory exists!" >&2
  fi
fi
