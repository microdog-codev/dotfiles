# Zsh + Zinit Handy Guide

This setup gives you a fast Zsh shell with a Starship prompt, command suggestions,
syntax highlighting, completions, vi-style editing, fuzzy search, and a curated
set of command-line tools. Zinit downloads and updates the plugins and tools.

## Install

You need Zsh, Git, an internet connection, and a terminal using a Nerd Font.
The font is optional, but some prompt icons will appear as boxes without it.

On Debian or Ubuntu:

```sh
sudo apt update
sudo apt install zsh git coreutils
zsh zsh/zinit/install.zsh
```

On macOS, install the command-line tools if Git is missing, then run the same
installer. Homebrew's `fzf` and `ripgrep` packages provide the two tools that
this configuration only downloads automatically on Linux:

```sh
xcode-select --install
brew install fzf ripgrep
zsh zsh/zinit/install.zsh
```

The installer links the shared files into your home directory, copies `.zshenv`
and `.zshrc.local` from `templates/` when they do not already exist, and opens
a login shell. Existing local files are preserved; replaced shared files are
moved into `~/.zsh-config-backup.XXXXXX` first.

To make Zsh the default shell, run this once and then log out and back in:

```sh
chsh -s "$(command -v zsh)"
```

## Everyday Cheatsheet

| What you want                                 | Key or command                       |
| --------------------------------------------- | ------------------------------------ |
| Complete a command or path                    | `Tab`                                |
| Search history matching what is already typed | `Up` / `Down` or `Ctrl-P` / `Ctrl-N` |
| Fuzzy-search all command history              | `Ctrl-R`                             |
| Fuzzy-find a file and paste its path          | `Ctrl-T`                             |
| Fuzzy-pick a directory and enter it           | `Alt-C`                              |
| Accept the gray command suggestion            | `Right Arrow` or `End`               |
| Edit the current command in `$EDITOR`         | `Ctrl-X`, then `Ctrl-E`              |
| Cancel the current command                    | `Ctrl-C`                             |
| Clear the screen                              | `Ctrl-L`                             |
| Stop a running foreground command             | `Ctrl-C`                             |
| Suspend a running command                     | `Ctrl-Z`; resume with `fg`           |

Completion is context-aware. Type part of a command, option, branch, file, or
directory and press `Tab`; press it again to move through choices.

### Vi editing

The command line starts in insert mode, so normal typing works as expected.
Press `Esc` for vi normal mode, then use these common keys:

| Key               | Action                                          |
| ----------------- | ----------------------------------------------- |
| `i` / `a`         | Insert before / after the cursor                |
| `I` / `A`         | Insert at the start / end of the line           |
| `h` `j` `k` `l`   | Move left, history down, history up, move right |
| `w` / `b`         | Move forward / backward by a word               |
| `0` / `$`         | Move to the start / end of the line             |
| `x`               | Delete one character                            |
| `dd`              | Delete the whole command line                   |
| `u` / `.`         | Undo / repeat the last change                   |
| `/text`, then `n` | Search history, then repeat the search          |

If vi mode feels unfamiliar, press `i` to return to normal typing.

## Moving Around

| Command             | Purpose                                             |
| ------------------- | --------------------------------------------------- |
| `z name`            | Jump to a frequently used directory matching `name` |
| `zi`                | Interactively choose a known directory              |
| `..`, `...`, `....` | Go up one, two, or three directory levels           |
| `path/to/folder`    | Enter a directory without typing `cd`               |
| `dirs -v`           | Show the directory stack                            |
| `cd -`              | Return to the previous directory                    |

`zoxide` learns from normal `cd` usage. Its results become better after a few
days of use.

## Files and Search

| Command    | Purpose                                                               |
| ---------- | --------------------------------------------------------------------- |
| `ls`       | Modern directory listing using `eza`                                  |
| `l`        | Long listing with file types and groups                               |
| `la`       | Long listing including hidden files                                   |
| `ll`       | Simple long listing                                                   |
| `lt`       | Long listing sorted by modification time                              |
| `ldot`     | List hidden entries                                                   |
| `fd name`  | Find files and directories by name                                    |
| `rg text`  | Search file contents recursively (Linux; install separately on macOS) |
| `bat file` | View a file with syntax highlighting                                  |
| `fzf`      | Interactively filter any list piped into it                           |

Useful combinations:

```sh
fd invoice
rg "words to find"
fd -e jpg | fzf
rg -l "project name" | fzf | xargs bat
```

## Git Shortcuts

These come from the Oh My Zsh Git plugin:

| Shortcut          | Expands to                         |
| ----------------- | ---------------------------------- |
| `g`               | `git`                              |
| `gst`             | `git status`                       |
| `ga file`         | `git add file`                     |
| `gaa`             | `git add --all`                    |
| `gcmsg "message"` | `git commit --message "message"`   |
| `gd`              | `git diff`                         |
| `gco branch`      | `git checkout branch`              |
| `gcb branch`      | `git checkout -b branch`           |
| `gl`              | `git pull`                         |
| `gp`              | `git push`                         |
| `glog`            | Compact decorated commit graph     |
| `lazygit`         | Full-screen interactive Git client |
| `gitleaks detect` | Scan a repository for secrets      |

Type `alias | rg '^g'` to see the complete, current Git alias list.

## Other Included Tools

| Command                     | Purpose                                         |
| --------------------------- | ----------------------------------------------- |
| `tldr command`              | Show short, example-based help for a command    |
| `httpstat URL`              | Show timing details for an HTTP request         |
| `gibo dump Python`          | Print a `.gitignore` template                   |
| `direnv allow`              | Approve a project's `.envrc` environment        |
| `mise use node@lts`         | Select a tool version for the current project   |
| `mise use -g python@latest` | Select a default tool version                   |
| `proxy` / `noproxy`         | Enable / disable proxy variables through `pctl` |
| `btop`                      | Interactive system monitor (Linux)              |

Use `tldr`, `command --help`, or `man command` whenever a command is unfamiliar.
Manual pages are colorized automatically.

## Personal Settings

Put private or machine-specific interactive settings in `~/.zshrc.local`. Do
not edit `~/.zshrc` directly: it is a symlink into this repository, so such
edits change the shared configuration.

Put environment settings needed by every Zsh invocation, such as `PATH`
updates, in `~/.zshenv` instead.

Example `~/.zshrc.local`:

```zsh
export WORKSPACE="$HOME/Projects"
alias cwork='cd "$WORKSPACE"'

# Deprecated: use uv for Python management instead.
# source ~/.zshrc.pyenv
# Preferred: uv completions for Python version and project management.
# source ~/.zshrc.uv
# source ~/.zshrc.miniserve
# source ~/.zshrc.git-diff
# source ~/.zshrc.gpg-agent
# source ~/.zshrc.gitllm
```

After changing it, start a clean shell so plugins and hooks are not loaded
twice:

```sh
exec zsh -l
```

### Optional modules

- `.zshrc.pyenv` is deprecated; it installs and initializes `pyenv` through
  Zinit. Use `uv` for Python version and project management instead.
- `.zshrc.uv` adds completions for an already installed `uv` command.
- `.zshrc.miniserve` installs the `miniserve` file server.
- `.zshrc.git-diff` adds `fgd`, an `fzf` picker with colored Git diff previews.
- `.zshrc.gpg-agent` configures GPG Agent and adds `gpg-tty` to repair its TTY.
- `.zshrc.gitllm` adds `gitllm`, which proposes and optionally creates a commit
  from staged changes. It requires the Datasette `llm` CLI and an API key. It
  scans with `gitleaks`, withholds obvious sensitive files, and sends the
  remaining staged context to the configured remote model; always review what
  is staged before using it.

## Maintenance

Update Zinit itself and all managed plugins/tools:

```sh
zinit self-update
zinit update --all
```

Useful diagnostics:

```sh
zinit loaded       # list loaded plugins
zinit times        # show plugin load timing
zinit completions  # list installed completions
zinit status --all # show locally changed plugin files
```

To pull configuration changes from this repository, run `git pull` in the
repository and then `exec zsh -l`.

## Troubleshooting

- **Prompt icons are boxes:** select a Nerd Font in the terminal's font settings.
- **A new command is not found immediately:** run `rehash`, or start a new shell.
- **A completion is stale:** run `zicompinit; zicdreplay`, then start a new shell.
- **The first launch reports download errors:** confirm Git and internet access,
  then run `zinit update --all`.
- **A local setting broke startup:** move `~/.zshrc.local` aside and run
  `exec zsh -l`; add its lines back one at a time.
- **GPG asks in the wrong terminal:** run `gpg-tty` if the optional GPG module is
  enabled.
- **Need the old configuration:** find the path printed by the installer under
  `~/.zsh-config-backup.XXXXXX` and move the wanted files back after removing
  their replacement symlinks.
