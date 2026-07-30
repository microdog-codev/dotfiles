#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
BACKUP_DIR=""

backup_file() {
  local path=$1

  if [[ -z "$BACKUP_DIR" ]]; then
    BACKUP_DIR=$(mktemp -d "$HOME/.tmux-config-backup.XXXXXX")
    printf 'Existing tmux files will be backed up under %s\n' "$BACKUP_DIR"
  fi

  mv -- "$path" "$BACKUP_DIR/$(basename -- "$path")"
}

install_config() {
  local source=$SCRIPT_DIR/.tmux.conf
  local target=$HOME/.tmux.conf

  if [[ -e "$target" || -L "$target" ]]; then
    if cmp -s -- "$source" "$target"; then
      printf '%s is already up to date.\n' "$target"
      return
    fi
    backup_file "$target"
  fi

  cp -- "$source" "$target"
  printf 'Installed %s\n' "$target"
}

install_tpm() {
  local tpm_dir=$HOME/.tmux/plugins/tpm

  if [[ -d "$tpm_dir/.git" ]]; then
    printf 'TPM is already installed at %s.\n' "$tpm_dir"
    return
  fi
  if [[ -e "$tpm_dir" || -L "$tpm_dir" ]]; then
    printf 'Cannot install TPM: %s exists but is not a Git checkout.\n' "$tpm_dir" >&2
    return 1
  fi

  mkdir -p -- "$(dirname -- "$tpm_dir")"
  git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
}

install_config
install_tpm

printf 'Start tmux, then press backtick followed by I to fetch plugins.\n'
