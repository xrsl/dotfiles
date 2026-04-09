# Dotfiles

Managed with [chezmoi](https://chezmoi.io).

## Setup on a new machine

**1. Install chezmoi**
```bash
brew install chezmoi
```

**2. Init and apply dotfiles**
```bash
chezmoi init --apply xrsl/dotfiles
```

This clones the repo, generates `~/.config/chezmoi/chezmoi.toml`, and applies all dotfiles in one step.

**3. Install tools**
```bash
~/.local/bin/install-tools              # all
~/.local/bin/install-tools just typst   # specific
```

## Daily usage

```bash
chezmoi edit ~/.zshrc          # edit a dotfile (auto-commits and pushes on save)
chezmoi add ~/.some-new-file   # track a new file
chezmoi update                 # pull latest and apply
chezmoi diff                   # preview changes without applying
chezmoi apply                  # apply changes
```

## Tracked files

`.zshrc` `.zprofile` `.gitconfig` `.gitignore_global` `.tmux.conf` `.profile` `.hushlogin`
`.config/ghostty/config` `.config/homebrew/Brewfile` `.config/nix/nix.conf`
`.local/bin/install-tools`

## Never track

`~/.ssh/*` `~/.aws/credentials`
