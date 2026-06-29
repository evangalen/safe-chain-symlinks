if ! type curl | grep -E "curl is a (shell )?function" > /dev/null; then
  echo "⊘  Please use \`source\` to execute this shell script:" >&2
  echo "source $0" >&2
  exit 1
fi

if [[ "$BUN_INSTALL" != "" ]]; then
  echo "⚠  Found existing BUN_INSTALL environment variable!"
  echo
fi

VERSION="${1:-}"

echo "⚒  Installing ${VERSION:-latest} version of bun"
if [[ "$VERSION" != "" ]]; then
  curl -fsSL https://bun.com/install | bash -s "bun-v$VERSION"
else
  curl -fsSL https://bun.sh/install | bash
fi
