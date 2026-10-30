#!/usr/bin/env bash
# Installe Typst (binaire statique) dans ~/.local/bin si absent.
set -euo pipefail
mkdir -p "$HOME/.local/bin"
if command -v typst >/dev/null 2>&1; then echo "Typst déjà présent : $(typst --version)"; exit 0; fi
ARCH="$(uname -m)"
URL="https://github.com/typst/typst/releases/latest/download/typst-${ARCH}-unknown-linux-musl.tar.xz"
tmp="$(mktemp -d)"; curl -sSL "$URL" -o "$tmp/t.tar.xz"
tar xf "$tmp/t.tar.xz" -C "$tmp"
cp "$tmp"/*/typst "$HOME/.local/bin/typst"; chmod +x "$HOME/.local/bin/typst"
rm -rf "$tmp"; echo "Typst installé : $("$HOME/.local/bin/typst" --version)"
