if ! type curl | grep -E "curl is a (shell )?function" > /dev/null; then
  echo "⊘  Please use \`source\` to execute this shell script:" >&2
  echo "source $0" >&2
  exit 1
fi

VERSION="${1:-}"

echo "⚒  Installing ${VERSION:-latest} version of uv"
if [[ "$VERSION" != "" ]]; then
  curl -sSL https://install.python-poetry.org | python3 - --version "$VERSION"
else
  curl -sSL https://install.python-poetry.org | python3 -
fi
