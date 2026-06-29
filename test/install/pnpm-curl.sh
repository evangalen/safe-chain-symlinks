if ! type curl | grep -E "curl is a (shell )?function" > /dev/null; then
  echo "⊘  Please use \`source\` to execute this shell script:" >&2
  echo "source $0" >&2
  exit 1
fi

if [[ "$PNPM_HOME" != "" ]]; then
  echo "⚠  Found existing PNPM_HOME environment variable!"
  echo
fi

VERSION="${1:-}"

echo "⚒  Installing ${VERSION:-latest} version of pnpm"
if [[ "$VERSION" != "" ]]; then
  curl -fsSL https://get.pnpm.io/install.sh | env PNPM_VERSION="$VERSION" sh -
else
  curl -fsSL https://get.pnpm.io/install.sh | sh -
fi
