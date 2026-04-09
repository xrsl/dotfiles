#!/usr/bin/env bash
set -euo pipefail

echo "Bootstrapping new machine..."

# Install Homebrew (macOS)
if [[ "$(uname)" == "Darwin" ]] && ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install chezmoi and apply dotfiles
if ! command -v chezmoi &>/dev/null; then
    echo "Installing chezmoi..."
    if command -v brew &>/dev/null; then
        brew install chezmoi
    else
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    fi
fi

echo "Applying dotfiles..."
chezmoi init --apply xrsl/dotfiles

# Install oh-my-zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install Brewfile packages (macOS)
if [[ "$(uname)" == "Darwin" ]] && command -v brew &>/dev/null; then
    echo "Installing Brewfile packages..."
    brew bundle --file="$HOME/.config/homebrew/Brewfile"
fi

echo "Done. Restart your shell."
