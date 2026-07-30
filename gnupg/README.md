# GnuPG Handoff Guide

This directory contains the shared GnuPG policy, GPG Agent settings, and the
optional macOS launch agents. It does **not** contain keys, passphrases, trust
data, or revocation certificates.

Each person should have a separate OpenPGP key. Share public keys and verify
their full fingerprints; never copy an entire `~/.gnupg` directory or give
another person a secret-key backup or passphrase.

## What This Setup Does

- Keeps `~/.gnupg` private and installs `gpg.conf` and `gpg-agent.conf` with
  mode `600`.
- Uses modern AES and SHA-2 preferences and suppresses version/comment metadata.
- Hides recipient key IDs with `throw-keyids`. This provides limited recipient
  privacy, but decryption must try each available secret key and some browser
  OpenPGP clients may be incompatible.
- Does not cache passphrases used for symmetric encryption.
- Lets `gpg-agent` serve as the SSH agent.
- Caches OpenPGP passphrases for one minute after use, with a two-minute hard
  limit. SSH passphrases use a one-hour sliding cache and an eight-hour hard
  limit.
- Prevents a desktop Pinentry program from maintaining a separate passphrase
  cache beyond the GPG Agent policy.

The installer never changes keyrings or secret keys. If a destination config
already exists, it tightens its permissions but preserves its contents and
prints the shared file to compare against.

## Install

### 1. Install GnuPG

On macOS with Homebrew:

```sh
brew install gnupg
```

Homebrew installs a terminal Pinentry program with GnuPG. For an optional native
macOS passphrase dialog, install `pinentry-mac`:

```sh
brew install pinentry-mac
```

Then uncomment the matching Homebrew path at the bottom of
`~/.gnupg/gpg-agent.conf` after running the installer. Apple Silicon normally
uses `/opt/homebrew`; Intel Macs normally use `/usr/local`.

On Debian or Ubuntu:

```sh
sudo apt update
sudo apt install gnupg pinentry-curses
```

Confirm that GnuPG 2.x is active:

```sh
gpg --version
```

### 2. Install the shared configuration

From the root of this dotfiles checkout:

```sh
bash gnupg/install.sh
```

The script can be run from any working directory. It creates `~/.gnupg` with
mode `700`, copies missing configuration files, checks both files with
`gpgconf`, reloads GPG Agent, and starts it on demand.

If it reports that an existing config was preserved, compare it before deciding
which local settings to retain:

```sh
diff -u ~/.gnupg/gpg.conf gnupg/gpg.conf
diff -u ~/.gnupg/gpg-agent.conf gnupg/gpg-agent.conf
```

After changing `gpg-agent.conf`, apply it with:

```sh
gpgconf --reload gpg-agent
```

### 3. Enable the Zsh integration

The dotfiles Zinit installer links `zinit/.zshrc.gpg-agent` into the home
directory. Enable it in `~/.zshrc.local`:

```zsh
source "$HOME/.zshrc.gpg-agent"
```

Start a clean login shell:

```sh
exec zsh -l
```

The module points `SSH_AUTH_SOCK` at GPG Agent, starts the agent, and updates
Pinentry to use the current terminal before every command. This replaces
`ssh-agent` inside that shell.

For a shell setup that does not use these dotfiles, add the following to its
interactive startup file:

```sh
export GPG_TTY="$(tty)"
unset SSH_AGENT_PID
export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
gpg-connect-agent /bye >/dev/null 2>&1
```

Run this after moving between local terminals, SSH sessions, or tmux sessions:

```sh
gpg-connect-agent updatestartuptty /bye
```

The Zsh module provides the shorter `gpg-tty` command for the same repair.

### 4. Optional macOS integration for GUI applications

The Zsh module is sufficient for terminal applications. macOS GUI applications
do not read `.zshrc`; if one must use GPG Agent for SSH, install the two launch
agents:

```sh
mkdir -p "$HOME/Library/LaunchAgents"
cp gnupg/gpg.agent.daemon.plist \
  "$HOME/Library/LaunchAgents/local.gnupg.gpg-agent.plist"
cp gnupg/set-ssh-auth-sock.plist \
  "$HOME/Library/LaunchAgents/local.gnupg.ssh-auth-sock.plist"

launchctl bootstrap "gui/$(id -u)" \
  "$HOME/Library/LaunchAgents/local.gnupg.gpg-agent.plist"
launchctl bootstrap "gui/$(id -u)" \
  "$HOME/Library/LaunchAgents/local.gnupg.ssh-auth-sock.plist"
```

The first job starts GPG Agent at login. The second sets `SSH_AUTH_SOCK` in the
per-user launchd environment without replacing or symlinking over Apple's SSH
socket. Restart affected GUI applications after installing it. To remove the
jobs:

```sh
launchctl bootout "gui/$(id -u)" \
  "$HOME/Library/LaunchAgents/local.gnupg.ssh-auth-sock.plist"
launchctl bootout "gui/$(id -u)" \
  "$HOME/Library/LaunchAgents/local.gnupg.gpg-agent.plist"
rm "$HOME/Library/LaunchAgents/local.gnupg.ssh-auth-sock.plist"
rm "$HOME/Library/LaunchAgents/local.gnupg.gpg-agent.plist"
```

## First-Time Key Setup

### Create a personal key

Skip this if restoring your own existing key. Do not import another person's
secret key.

```sh
gpg --full-generate-key
```

Use the current GnuPG defaults unless compatibility requires something else.
Enter your own name and email, choose an expiration policy you will remember to
maintain, and protect the key with a unique passphrase.

List the new key and copy its complete fingerprint:

```sh
gpg --list-secret-keys --keyid-format 0xlong
gpg --fingerprint YOUR_EMAIL
```

Use the full fingerprint—not an email address or short key ID—for exports,
backup names, trust decisions, and destructive operations. The examples below
use these placeholders:

```sh
export MY_FPR="YOUR_40_HEX_CHARACTER_FINGERPRINT"
export PARTNER_FPR="THEIR_40_HEX_CHARACTER_FINGERPRINT"
```

Fingerprints are public. Secret-key files and revocation certificates are not.

### Make the recovery backup immediately

GnuPG creates a revocation certificate in `openpgp-revocs.d` when it generates a
key. Back up that certificate, the secret key, the public key, and ownertrust to
**encrypted offline storage**. Replace the example directory first:

```sh
export BACKUP="/path/to/encrypted-offline-storage/gnupg-backup"
mkdir -m 700 "$BACKUP"
umask 077

gpg --armor --export-options backup --export-secret-keys "$MY_FPR" \
  > "$BACKUP/$MY_FPR-secret-backup.asc"
gpg --armor --export "$MY_FPR" \
  > "$BACKUP/$MY_FPR-public.asc"
gpg --export-ownertrust \
  > "$BACKUP/ownertrust.txt"
cp "$(gpgconf --list-dirs homedir)/openpgp-revocs.d/$MY_FPR.rev" \
  "$BACKUP/$MY_FPR-revocation.rev"
```

Disconnect the backup when finished. A secret-key export remains highly
sensitive even when its key packets are passphrase-protected. Anyone holding the
revocation certificate can invalidate the public key.

Test recovery on a separate machine or in a temporary GnuPG home before relying
on the backup. Restore with:

```sh
gpg --import-options restore --import "$BACKUP/$MY_FPR-secret-backup.asc"
gpg --import-ownertrust "$BACKUP/ownertrust.txt"
gpg --list-secret-keys --fingerprint "$MY_FPR"
```

Do **not** import the revocation certificate during a normal restore. It is only
for retiring a lost or compromised key.

## Exchange and Verify Public Keys

Export a shareable public key:

```sh
gpg --armor --export "$MY_FPR" > "$MY_FPR-public.asc"
```

The `.asc` public-key file can be sent normally. The recipient should inspect it
before import:

```sh
gpg --show-keys --fingerprint partner-public.asc
gpg --import partner-public.asc
gpg --fingerprint "$PARTNER_FPR"
```

Compare the complete fingerprint over a different trusted channel, such as in
person or a known phone call. An email arriving with the key is not an
independent fingerprint check.

After the fingerprint matches, create a local, non-exportable certification:

```sh
gpg --quick-lsign-key "$PARTNER_FPR"
```

Do not assign `ultimate` ownertrust to somebody else's key. Ultimate ownertrust
is for keys whose certification policy and secret key you personally control.

## Daily Cheatsheet

### Inspect keys and configuration

| Task | Command |
| --- | --- |
| List public keys | `gpg --list-keys` |
| List secret keys | `gpg --list-secret-keys` |
| Show one full fingerprint | `gpg --fingerprint "$MY_FPR"` |
| Inspect a key file without importing | `gpg --show-keys --fingerprint public.asc` |
| Show the GnuPG home | `gpgconf --list-dirs homedir` |
| Show the GPG Agent SSH socket | `gpgconf --list-dirs agent-ssh-socket` |
| Check client config | `gpgconf --check-options gpg` |
| Check agent config | `gpgconf --check-options gpg-agent` |

### Import and share public keys

| Task | Command |
| --- | --- |
| Import a key file | `gpg --import public.asc` |
| Export a public key | `gpg --armor --export "$MY_FPR" > public.asc` |
| Refresh a known public key from its configured source | `gpg --refresh-keys "$PARTNER_FPR"` |
| Locally certify a verified fingerprint | `gpg --quick-lsign-key "$PARTNER_FPR"` |

Publishing to a public keyserver is deliberately not automatic. Publication may
be difficult to undo and exposes identity metadata; agree on the keyserver and
fingerprint first.

### Encrypt and decrypt files

Encrypt for the partner **and yourself** so either person can decrypt the copy:

```sh
gpg --output report.pdf.gpg --encrypt \
  --recipient "$PARTNER_FPR" \
  --recipient "$MY_FPR" \
  report.pdf
```

Decrypt to an explicit output file:

```sh
gpg --output report.pdf --decrypt report.pdf.gpg
```

Encrypt with only a shared passphrase, without public keys:

```sh
gpg --output archive.tar.gpg --symmetric archive.tar
```

Enter the passphrase only in Pinentry, never as a command-line argument. Send it
through a different channel from the encrypted file. This setup intentionally
does not cache symmetric-encryption passphrases.

### Sign and verify files

Create an ASCII-armored detached signature:

```sh
gpg --armor --detach-sign --local-user "$MY_FPR" report.pdf
```

Send both `report.pdf` and `report.pdf.asc`. Verify by naming both files
explicitly:

```sh
gpg --verify report.pdf.asc report.pdf
```

A successful cryptographic signature proves only that the signing key produced
it. It identifies a person only after the signer's full fingerprint has been
verified.

For short human-readable text:

```sh
gpg --clearsign --local-user "$MY_FPR" message.txt
gpg --verify message.txt.asc
```

Detached signatures are preferable for arbitrary files because clear-signing
can normalize text line endings and whitespace.

### Git commit signing (optional)

```sh
git config --global user.signingkey "$MY_FPR"
git config --global commit.gpgsign true
git commit -S
git log --show-signature -1
```

The configured key needs signing capability. Verify the fingerprint shown by a
Git hosting service before marking commits as verified there.

### SSH through GPG Agent

Confirm that the shell is using GPG Agent and list offered keys:

```sh
printf '%s\n' "$SSH_AUTH_SOCK"
gpgconf --list-dirs agent-ssh-socket
ssh-add -l
ssh-add -L
```

The first two socket paths should match. A smartcard authentication key is
offered while its card is present; inspect the card with:

```sh
gpg --card-status
```

A normal OpenSSH private key can instead be imported into GPG Agent once:

```sh
ssh-add "$HOME/.ssh/id_ed25519"
```

GPG Agent may ask first for the existing SSH key passphrase and then for the
passphrase used to protect its stored copy. Confirm the resulting public key
with `ssh-add -L` before registering it anywhere.

## Troubleshooting and Maintenance

| Symptom or task | Command / action |
| --- | --- |
| Pinentry opens on the wrong terminal | `gpg-tty` |
| Apply an edited agent config | `gpgconf --reload gpg-agent` |
| Clear cached passphrases now | `gpgconf --kill gpg-agent` |
| Start the agent again | `gpg-connect-agent /bye` |
| SSH is using the wrong agent | Compare `$SSH_AUTH_SOCK` with `gpgconf --list-dirs agent-ssh-socket` |
| No SSH key is offered | Run `ssh-add -L`; insert the smartcard or import the intended SSH key |
| Pinentry is missing | Install `pinentry-curses`, or install/configure `pinentry-mac` on macOS |
| GnuPG warns about unsafe permissions | Run `chmod 700 ~/.gnupg` and `chmod 600 ~/.gnupg/*.conf` |
| Show component versions | `gpgconf --show-versions` |

After killing GPG Agent, the next GnuPG request or `gpg-connect-agent /bye`
starts it again. The first protected operation will prompt for a passphrase.

Before a key or subkey expires, update its expiration, export the updated public
key, and redistribute it. Use the interactive editor when needed:

```sh
gpg --edit-key "$MY_FPR"
```

At the `gpg>` prompt, use `expire`, then `save`. Do not guess through key-editing
operations involving revocation or deletion; consult `gpg --help` or the GnuPG
manual first.

## Lost or Compromised Key

1. Disconnect the affected device if compromise is suspected.
2. Retrieve the offline revocation certificate.
3. Import it into a safe GnuPG installation:

   ```sh
   gpg --import "$BACKUP/$MY_FPR-revocation.rev"
   gpg --armor --export "$MY_FPR" > "$MY_FPR-revoked-public.asc"
   ```

4. Distribute or publish the newly revoked public key anywhere the old public
   key was shared.
5. Generate a new personal key and verify its fingerprint through trusted
   channels.

Do not delete the old local key material until the revocation and required old
file decryption have been confirmed. Without either the secret primary key or a
saved revocation certificate, a lost key generally cannot be revoked.

## Reference

- [GnuPG 2.4 `gpg` manual](https://www.gnupg.org/documentation/manuals/gnupg24/gpg.1.html)
- [GnuPG 2.4 `gpg-agent` manual](https://www.gnupg.org/documentation/manuals/gnupg24/gpg-agent.1.html)
- [GnuPG 2.4 `gpgconf` manual](https://www.gnupg.org/documentation/manuals/gnupg24/gpgconf.1.html)
- [Homebrew GnuPG formula](https://formulae.brew.sh/formula/gnupg)
- [Homebrew pinentry-mac formula](https://formulae.brew.sh/formula/pinentry-mac)
