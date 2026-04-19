#!/usr/bin/env bash
set -euo pipefail

# Install terminal environment: chezmoi, oh-my-zsh, zsh plugins
# Run this first on a new Mac before anything else.

echo "Installing chezmoi and Ghostty..."
brew install chezmoi
if brew list --cask ghostty &>/dev/null; then
    echo "ghostty already installed, skipping"
else
    brew install --cask ghostty
fi

echo "Installing eza..."
if brew list eza &>/dev/null; then
    echo "eza already installed, skipping"
else
    brew install eza
fi

echo "Installing JetBrainsMono Nerd Font..."
if brew list --cask font-jetbrains-mono-nerd-font &>/dev/null; then
    echo "font-jetbrains-mono-nerd-font already installed, skipping"
else
    brew install --cask font-jetbrains-mono-nerd-font
fi

echo "Installing oh-my-zsh..."
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "oh-my-zsh already installed, skipping"
fi

echo "Installing zsh plugins and theme..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]]; then
    echo "Installing spaceship-prompt..."
    git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
    ln -sf "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
    echo "spaceship-prompt installed"
else
    echo "spaceship-prompt already installed, skipping"
fi

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
