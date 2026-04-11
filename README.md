# Dotfiles

Managed with [chezmoi](https://chezmoi.io).

## Setup on a new machine

**1. Install terminal environment** (chezmoi, oh-my-zsh, zsh plugins, dotfiles)
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/xrsl/dotfiles/main/install-terminal.sh)"
```

**Optional: install Homebrew packages**
```bash
brew bundle --file="~/.config/homebrew/Brewfile"
```

**Optional: install CLI tools (Linux)**
```bash
~/.local/bin/install-tools              # all
~/.local/bin/install-tools just typst   # specific
```

## Daily usage

```bash
chezmoi edit ~/.zshrc                    # edit a dotfile (auto-commits and pushes on save)
chezmoi add ~/.some-new-file             # track a new file
chezmoi update                           # pull latest and apply
chezmoi diff                             # preview changes without applying
chezmoi apply                            # apply changes
chezmoi status                           # see pending changes
chezmoi managed --include=files          # list all tracked files
chezmoi init                             # regenerate config from template (run after template changes)

# for repo-only files (README, install scripts) not managed by chezmoi:
cd ~/.local/share/chezmoi && git add -A && git commit -m "msg" && git push
```

## Tracked files

```
.config/ghostty/config
.config/homebrew/Brewfile
.config/nix/nix.conf
.gitconfig
.gitignore_global
.hushlogin
.local/bin/install-tools
.profile
.tmux.conf
.zprofile
.zshrc
```

## Never track

`~/.ssh/*` `~/.aws/credentials`
