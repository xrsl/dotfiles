# Dotfiles

Managed with [chezmoi](https://chezmoi.io).

## Setup on a new machine

```bash
chezmoi init --apply xrsl/dotfiles
```

**Optional: install Homebrew packages**
```bash
brew bundle --file="~/.config/homebrew/Brewfile"
```

**Optional: install oh-my-zsh**
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
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
