# Dotfiles

Managed with [chezmoi](https://chezmoi.io).

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

Start the VM and bootstrap the mise-managed development environment from macOS:

```bash
vmu ubuntu && ssh -t ubuntu 'sudo apt-get update && sudo apt-get install -y ca-certificates curl git zsh build-essential && curl -fsSL https://mise.run | sh && MISE_GLOBAL_CONFIG_FILE=/dev/null ~/.local/bin/mise exec chezmoi@latest -- chezmoi init --apply https://github.com/xrsl/dotfiles.git && ~/.local/bin/mise install --locked && chsh -s "$(command -v zsh)"'
```

After the first setup, start and enter it with `vmu ubuntu && ssh ubuntu`.

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

```bash
chezmoi edit ~/.zshrc                    # edit a dotfile (auto-commits and pushes on save)
chezmoi add ~/.some-new-file             # track a new file
chezmoi update                           # pull latest and apply
chezmoi diff                             # preview changes without applying
chezmoi apply                            # apply changes
chezmoi status                           # see pending changes
chezmoi managed --include=files          # list all tracked files
chezmoi init                             # regenerate config from template (run after template changes)

# for repo-only files (README and bootstrap script) not managed by chezmoi:
cd ~/.local/share/chezmoi && git add -A && git commit -m "msg" && git push
```

> **Warning:** auto-commit only works for chezmoi-managed dotfiles
> (`chezmoi add`/`chezmoi edit`). Commit repo-only files directly from the source
> directory.

## Never track

`~/.ssh/*` `~/.aws/credentials` plaintext tokens or passwords
