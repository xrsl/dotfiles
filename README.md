# Dotfiles

Bare git repo - no symlinks, no tools.

## Setup

```bash
curl -fsSL https://raw.githubusercontent.com/xrsl/dotfiles/main/bootstrap.sh | bash
```

## Usage

```bash
dotfiles status              # see changes
dotfiles add ~/.config       # track file
dotfiles commit -m "update"  # commit
dotfiles push                # sync
```

## Tracked

`.zshrc` `.zprofile` `.gitconfig` `.tmux.conf` `.profile`

## Tools

```bash
~/.local/bin/install-tools              # all
~/.local/bin/install-tools just typst   # specific
```

Never track: `~/.ssh/*` `~/.aws/credentials`
