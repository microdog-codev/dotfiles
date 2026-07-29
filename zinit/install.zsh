#!/usr/bin/env zsh

set -euo pipefail

echo "Installing zsh env with zinit..."

DIR="${0:A:h}"
BACKUP_DIR=""

link_config() {
    local source_path="$1"
    local target_path="$2"

    if [[ -e "$target_path" || -L "$target_path" ]]; then
        if [[ "$source_path" -ef "$target_path" ]]; then
            return
        fi

        if [[ -z "$BACKUP_DIR" ]]; then
            BACKUP_DIR="$(mktemp -d "$HOME/.zsh-config-backup.XXXXXX")"
        fi
        mv "$target_path" "$BACKUP_DIR/${target_path:t}"
    fi

    ln -s "$source_path" "$target_path"
}

echo "Copy configs..."
mkdir -p "$HOME/.config"
for source_path in "$DIR"/.zshrc*(N); do
    link_config "$source_path" "$HOME/${source_path:t}"
done
link_config "$DIR/starship.toml" "$HOME/.config/starship.toml"

if [[ -n "$BACKUP_DIR" ]]; then
    echo "Existing configs backed up to $BACKUP_DIR"
fi

if [[ ! -f ~/.zshrc.local ]]; then
    tee -a ~/.zshrc.local >/dev/null <<EOF
#source ~/.zshrc.pyenv
#source ~/.zshrc.git-diff
#source ~/.zshrc.gpg-agent
EOF
fi

if [[ ! -f ~/.zshenv ]]; then
    tee -a ~/.zshenv >/dev/null <<EOF
#PCTL_PROXY_ADDRESS=127.0.0.1
#PCTL_PROXY_PORT=6152

#NO_PROXY=localhost,127.0.0.0

#skip_global_compinit=1
EOF
fi

exec zsh -l
