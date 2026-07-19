# Dotfiles

Managed with [chezmoi](https://chezmoi.io) and [mise](https://mise.jdx.dev).

## New machine

Run once:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/xrsl/dotfiles/main/bootstrap.sh)"
```

The bootstrap order is:

1. Homebrew and the macOS command-line prerequisites
2. mise
3. chezmoi, run once through mise to apply this repository
4. Homebrew libraries, applications, Zsh plugins, and fonts
5. mise-managed developer runtimes and CLI tools
6. a fresh login Zsh

Homebrew state is declared in `~/.config/homebrew/Brewfile`. Developer tools and
runtimes are declared in `~/.config/mise/config.toml` and pinned across macOS and
Linux ARM64 by `~/.config/mise/mise.lock`.

The terminal font is `font-jetbrains-mono-nerd-font`; Ghostty uses
`JetBrainsMono Nerd Font Mono`.

## Ubuntu Tart VM

Start and enter the VM from macOS:

```bash
vmu ubuntu
ssh ubuntu
```

Inside Ubuntu, bootstrap the chezmoi- and mise-managed development environment
with these separate commands:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl git zsh build-essential
curl -fsSL https://mise.run | sh
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
MISE_GLOBAL_CONFIG_FILE=/dev/null mise exec chezmoi@latest -- chezmoi init --apply https://github.com/xrsl/dotfiles.git
mise install --locked
chsh -s "$(command -v zsh)"
exec zsh -l
```

After the first setup, start and enter it with `vmu ubuntu && ssh ubuntu`.

## Fedora Tart VM

```bash
tart clone ghcr.io/cirruslabs/fedora:latest fedora
vmu fedora
ssh tart-fedora
sudo dnf install -y ca-certificates curl git zsh gcc gcc-c++ make util-linux-user
curl -fsSL https://mise.run | sh
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
MISE_GLOBAL_CONFIG_FILE=/dev/null mise --verbose install chezmoi@latest
git clone https://github.com/xrsl/dotfiles.git ~/.local/share/chezmoi
MISE_GLOBAL_CONFIG_FILE=/dev/null mise exec chezmoi@latest -- chezmoi init
MISE_GLOBAL_CONFIG_FILE=/dev/null mise exec chezmoi@latest -- chezmoi apply --verbose
mise trust ~/.config/mise/config.toml
mise install --locked
exec zsh -l
```

## Reconcile an existing machine

```bash
chezmoi update
brew bundle --file="$HOME/.config/homebrew/Brewfile"
mise install
```

To add a mise tool and save its lockfile:

```bash
mise use --global <tool>@latest          # updates config + lock
mise lock --global                      # only needed after editing config.toml by hand
mise install --locked                   # verify the locked install
chezmoi add ~/.config/mise/{config.toml,mise.lock}
```

## Daily usage

Three commands cover almost everything.
Auto-commit and auto-push are on, so saving a change also commits and pushes it — there is no separate `git` step.

```bash
chezmoi re-add     # 1. SAVE UP:   this machine's edits -> repo (commit + push)
chezmoi update     # 2. PULL DOWN: repo -> this machine (git pull + apply)
chezmoi diff       # 3. CHECK:     what differs, before you touch anything
```

Mental model: **check** (`diff`) → **save up** (`re-add`) → **pull down** (`update`).

Two more, only occasionally:

```bash
chezmoi add ~/.newfile     # 4. track a NEW file (once); re-add handles it afterwards
chezmoi edit ~/.zshrc      # 5. edit a tracked file in place (also auto-commits + pushes)
```

### The one gotcha

Auto-commit/push fires **only for chezmoi-managed dotfiles**.
This README and `bootstrap.sh` live in the repo but are not managed by chezmoi, so editing them needs a plain git commit from the source dir:

```bash
chezmoi cd     # open a shell in the source repo (~/.local/share/chezmoi)
git add -A && git commit -m "msg" && git push
exit
```

## Never track

`~/.ssh/*` `~/.aws/credentials` plaintext tokens or passwords
