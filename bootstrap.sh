#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/.dotfiles"
REPO="https://github.com/xrsl/dotfiles.git"

echo "🔧 Bootstrapping dotfiles..."

if [[ ! -d "$DOTFILES" ]]; then
    echo "📦 Cloning dotfiles repo..."
    git clone --bare "$REPO" "$DOTFILES"
fi

echo "📥 Applying dotfiles..."
git --git-dir="$DOTFILES" --work-tree="$HOME" fetch
git --git-dir="$DOTFILES" --work-tree="$HOME" reset --hard origin/main
git --git-dir="$DOTFILES" --work-tree="$HOME" config status.showUntrackedFiles no

echo "✅ Dotfiles applied"
echo "➡️  Try: dotfiles status"
