# Dotfiles

Bare git repo approach - no symlinks, no tools.

## New Machine Setup

```bash
# One-liner (fresh machine)
git clone --bare https://github.com/xrsl/dotfiles.git ~/.dotfiles && git --git-dir=$HOME/.dotfiles --work-tree=$HOME checkout -f && git --git-dir=$HOME/.dotfiles --work-tree=$HOME config status.showUntrackedFiles no && source ~/.zshrc

# Or step by step:
git clone --bare https://github.com/xrsl/dotfiles.git ~/.dotfiles
git --git-dir=$HOME/.dotfiles --work-tree=$HOME checkout -f
git --git-dir=$HOME/.dotfiles --work-tree=$HOME config status.showUntrackedFiles no
source ~/.zshrc
```

If checkout fails due to existing files:
```bash
mkdir -p ~/.dotfiles-backup
git --git-dir=$HOME/.dotfiles --work-tree=$HOME checkout 2>&1 | grep -E "^\s+" | awk '{print $1}' | xargs -I{} mv {} ~/.dotfiles-backup/{}
git --git-dir=$HOME/.dotfiles --work-tree=$HOME checkout -f
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

## Quick Commands (before alias is loaded)

```bash
# Pull latest and reload
git --git-dir=$HOME/.dotfiles --work-tree=$HOME pull && source ~/.zshrc

# Force checkout (overwrites local files)
git --git-dir=$HOME/.dotfiles --work-tree=$HOME checkout -f

# Check status
git --git-dir=$HOME/.dotfiles --work-tree=$HOME status
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

## CLI Tools

### macOS (Homebrew)

```bash
brew bundle --file=~/.config/homebrew/Brewfile
```

### Linux

```bash
# All tools
~/.local/bin/install-tools

# Specific tools
~/.local/bin/install-tools cue just starship
```

Available: `cue just starship yq gh watchexec typos typst jq tombi`

## Never Track

- `~/.ssh/*` - Generate fresh keys per machine
- `~/.aws/credentials` - Machine-specific secrets
- Any file with tokens/passwords
