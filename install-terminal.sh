#!/usr/bin/env bash
set -euo pipefail

# Install terminal environment: chezmoi, oh-my-zsh, zsh plugins, starship
# Run this first on a new Mac before anything else.

echo "Installing chezmoi..."
brew install chezmoi

echo "Installing tools from Brewfile..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
brew bundle install --file="$SCRIPT_DIR/Brewfile"

echo "Installing starship..."
brew install starship

echo "Installing fonts..."
brew install --cask font-iosevka-nerd-font font-iosevka-term-nerd-font font-iosevka-term-slab-nerd-font

echo "Installing oh-my-zsh..."
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "oh-my-zsh already installed, skipping"
fi

echo "Installing zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
    echo "zsh-autosuggestions already installed, skipping"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
    echo "zsh-syntax-highlighting already installed, skipping"
fi

echo "Applying dotfiles..."
chezmoi init --apply xrsl/dotfiles

echo "Done. Restart your terminal."
