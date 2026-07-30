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

for config_name in .zshenv .zshrc.local; do
    target_path="$HOME/$config_name"
    if [[ ! -e "$target_path" && ! -L "$target_path" ]]; then
        cp "$DIR/templates/$config_name" "$target_path"
    fi
done

exec zsh -l
