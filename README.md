# Dotfiles

Bare git repo approach - no symlinks, no tools.

## New Machine Setup

```bash
# Clone the bare repo
git clone --bare https://github.com/xrsl/dotfiles.git ~/.dotfiles

# Define the alias temporarily
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# Checkout files to home directory
dotfiles checkout

# If checkout fails due to existing files, back them up first:
# mkdir -p ~/.dotfiles-backup
# dotfiles checkout 2>&1 | grep -E "^\s+" | awk '{print $1}' | xargs -I{} mv {} ~/.dotfiles-backup/{}
# dotfiles checkout

# Hide untracked files in status
dotfiles config status.showUntrackedFiles no
```

## Daily Usage

```bash
dotfiles status                  # see changes
dotfiles diff                    # see what changed
dotfiles add ~/.someconfig       # track a new file
dotfiles add -u                  # stage all tracked changes
dotfiles commit -m "message"     # commit
dotfiles push                    # sync to GitHub
```

## Tracked Files

- `.zshrc` - Zsh config (oh-my-zsh, spaceship theme, plugins)
- `.zprofile` - Zsh profile
- `.gitconfig` - Git settings
- `.tmux.conf` - Tmux config
- `.profile` - Shell profile

## Adding New Files

```bash
dotfiles add ~/.newconfig
dotfiles commit -m "Add newconfig"
dotfiles push
```

## Never Track

- `~/.ssh/*` - Generate fresh keys per machine
- `~/.aws/credentials` - Machine-specific secrets
- Any file with tokens/passwords
