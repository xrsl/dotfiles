#!/usr/bin/env bash
set -euo pipefail

echo "Bootstrapping dotfiles..."

# Homebrew owns machine-global libraries, applications, fonts, and Zsh plugins.
if [[ "$(uname -s)" == "Darwin" ]]; then
    if ! command -v brew >/dev/null 2>&1; then
        echo "Installing Homebrew..."
        /bin/bash -c \
            "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# mise is the bootstrap root and owns developer runtimes and CLI tools.
if command -v mise >/dev/null 2>&1; then
    MISE_BIN="$(command -v mise)"
else
    echo "Installing mise..."
    curl -fsSL https://mise.run | sh
    MISE_BIN="$HOME/.local/bin/mise"
fi

# Isolate chezmoi from any stale managed mise config during bootstrap.
echo "Applying dotfiles..."
if [[ -d "$HOME/.local/share/chezmoi/.git" ]]; then
    MISE_GLOBAL_CONFIG_FILE=/dev/null "$MISE_BIN" exec chezmoi@latest -- \
        chezmoi update
else
    MISE_GLOBAL_CONFIG_FILE=/dev/null "$MISE_BIN" exec chezmoi@latest -- \
        chezmoi init --apply https://github.com/xrsl/dotfiles.git
fi

if command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew packages..."
    brew bundle --file="$HOME/.config/homebrew/Brewfile"
fi

echo "Installing mise tools..."
"$MISE_BIN" install --locked

echo "Bootstrap complete. Starting a fresh login shell."
exec /bin/zsh -l
