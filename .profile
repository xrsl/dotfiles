
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

[[ -f "$HOME/.atuin/bin/env" ]] && . "$HOME/.atuin/bin/env"

if [ -e /home/xrsl/.nix-profile/etc/profile.d/nix.sh ]; then . /home/xrsl/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
