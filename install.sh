#!/bin/sh
# gitkai installer — https://github.com/ooookai/gitkai
#
#   curl -fsSL https://raw.githubusercontent.com/ooookai/gitkai/main/install.sh | sh
#
#   GITKAI_VERSION=v0.YYYYMMDD.N   install a specific version (default: latest)
#   GITKAI_INSTALL_DIR=<dir>       install destination (default: ~/.local/bin)
set -eu

REPO="ooookai/gitkai"
INSTALL_DIR="${GITKAI_INSTALL_DIR:-$HOME/.local/bin}"

case "$(uname -s)" in
  Darwin) os="macos" ;;
  Linux) os="linux" ;;
  *) echo "gitkai: unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac
case "$(uname -m)" in
  arm64 | aarch64) arch="arm64" ;;
  x86_64 | amd64) arch="x64" ;;
  *) echo "gitkai: unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

# Homebrew owns its installs — don't shadow one (two updaters must never fight).
if command -v brew >/dev/null 2>&1 && brew list gitkai >/dev/null 2>&1; then
  echo "gitkai is installed via Homebrew — use: brew upgrade gitkai" >&2
  exit 1
fi

tag="${GITKAI_VERSION:-}"
if [ -z "$tag" ]; then
  tag=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" |
    sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
fi
if [ -z "$tag" ]; then
  echo "gitkai: could not resolve the latest release" >&2
  exit 1
fi
case "$tag" in v*) ;; *) tag="v$tag" ;; esac
version="${tag#v}"

asset="gitkai-$version-$os-$arch.tar.gz"
url="https://github.com/$REPO/releases/download/$tag/$asset"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

echo "downloading gitkai $tag ($os-$arch)…"
curl -fsSL -o "$tmp/$asset" "$url"
curl -fsSL -o "$tmp/$asset.sha256" "$url.sha256"

if command -v sha256sum >/dev/null 2>&1; then
  (cd "$tmp" && sha256sum -c "$asset.sha256" >/dev/null)
else
  (cd "$tmp" && shasum -a 256 -c "$asset.sha256" >/dev/null)
fi

tar -xzf "$tmp/$asset" -C "$tmp"
mkdir -p "$INSTALL_DIR"
install -m 755 "$tmp/gitkai" "$INSTALL_DIR/gitkai"

echo "installed gitkai $tag → $INSTALL_DIR/gitkai"
case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *) echo "note: $INSTALL_DIR is not on your PATH" ;;
esac
