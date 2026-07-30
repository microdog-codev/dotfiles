#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
GPG_HOME=${GNUPGHOME:-"$HOME/.gnupg"}

for required_command in gpg gpgconf gpg-connect-agent; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'Missing %s. Install GnuPG before running this installer.\n' \
      "$required_command" >&2
    exit 1
  fi
done

mkdir -p "$GPG_HOME"
chmod 700 "$GPG_HOME"
export GNUPGHOME=$GPG_HOME

install_config() {
  local config_name=$1
  local source=$SCRIPT_DIR/$config_name
  local target=$GPG_HOME/$config_name

  if [[ -e "$target" || -L "$target" ]]; then
    chmod 600 "$target"
    if cmp -s "$source" "$target"; then
      printf '%s is already up to date.\n' "$target"
    else
      printf 'Preserved existing %s; compare it with %s.\n' "$target" "$source"
    fi
    return
  fi

  cp "$source" "$target"
  chmod 600 "$target"
  printf 'Installed %s\n' "$target"
}

install_config gpg.conf
install_config gpg-agent.conf

gpgconf --check-options gpg >/dev/null
gpgconf --check-options gpg-agent >/dev/null
gpgconf --reload gpg-agent
gpg-connect-agent /bye >/dev/null

printf 'GnuPG configuration is ready. Enable the GPG Agent shell module next.\n'
