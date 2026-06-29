if ! type curl | grep -E "curl is a (shell )?function" > /dev/null; then
  echo "⊘  Please use \`source\` to execute this shell script:" >&2
  echo "source $0" >&2
  exit 1
fi

VERSION="${1:-}"

echo "⚒  Installing ${VERSION:-latest} version of pdm"
if [[ "$VERSION" != "" ]]; then
  curl -sSL https://pdm-project.org/install.sh | bash -s -- -v "$VERSION"
else
  curl -sSL https://pdm-project.org/install.sh | bash
fi
