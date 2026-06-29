if ! type curl | grep -E "curl is a (shell )?function" > /dev/null; then
  echo "⊘  Please use \`source\` to execute this shell script:" >&2
  echo "source $0" >&2
  exit 1
fi

if [[ ! -e ~/.local/bin/uv ]]; then
  echo "⊘  No \`uv\` found in ~/.local/bin" >&2
else
  echo "⚒  Clean up stored data"
  NO_SAFE_CHAIN_SYMLINKS_VERIFY="true" ~/.local/bin/uv cache clean

  UV_PYTHON_DIR="$(~/.local/bin/uv python dir)"
  if [[ -e "$UV_PYTHON_DIR" ]]; then
    rm -rf ""$UV_PYTHON_DIR""
  fi

  UV_TOOL_DIR="$(~/.local/bin/uv tool dir)"
  if [[ -e "$UV_TOOL_DIR" ]]; then
    rm -rf "$UV_TOOL_DIR"
  fi

  echo "⚒  Removing \`uv\` and \`uvx\` in ~/.local/bin/uvx"
  rm -f ~/.local/bin/uv ~/.local/bin/uvx
fi
