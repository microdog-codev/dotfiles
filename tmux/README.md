# tmux Handy Guide

This setup keeps terminal work alive when a connection drops, and organizes it
into sessions, windows, and panes. It uses a plain backtick (`` ` ``) as the
command prefix, vi-style copy mode, a system status display, and plugins for
session save and restore.

## The Basic Model

- A **session** is a workspace, usually one per project.
- A **window** is a tab inside a session.
- A **pane** is a split terminal inside a window.

Most tmux shortcuts are two separate key presses: tap the prefix `` ` ``, let
go, and then press the command key. For example, `` ` `` followed by `c` opens
a window. Do not hold the two keys together.

## Install

You need tmux, Git, Bash, CMake, a C++ compiler, and Make. The build tools are
used by the CPU, memory, and network status plugin.

On Debian or Ubuntu:

```sh
sudo apt update
sudo apt install tmux git bash cmake build-essential
bash tmux/install.sh
```

On macOS with Homebrew:

```sh
brew install tmux cmake
bash tmux/install.sh
```

The installer copies the shared configuration to `~/.tmux.conf` and installs
TPM, the tmux plugin manager. If `~/.tmux.conf` already differs, it is moved
under `~/.tmux-config-backup.XXXXXX` first.

Start tmux, then install the remaining plugins by pressing `` ` `` followed by
capital `I`:

```sh
tmux
```

The status area should show CPU, memory, load, and network activity after the
plugin finishes building. Detach with `` ` `` then `d`; the session continues
running in the background.

## Start, Leave, and Return

| What you want                       | Command or key              |
| ----------------------------------- | --------------------------- |
| Start tmux in a new session         | `tmux`                      |
| Create a named session (optional)   | `tmux new -s work`          |
| List sessions                       | `tmux ls`                   |
| Attach to the most recent session   | `tmux attach`               |
| Attach to a named session           | `tmux attach -t work`       |
| Detach and leave it running         | `` ` `` then `d`            |
| Choose another session              | `` ` `` then `s`            |
| Rename the current session          | `` ` `` then `$`            |
| Move to the previous / next session | `` ` `` then `(` / `)`      |
| Stop a named session                | `tmux kill-session -t work` |

Closing the terminal, losing SSH, or detaching does not stop programs in tmux.
Typing `exit` closes only the current pane. A session ends after its final pane
is closed.

## Windows

| What you want                  | Key                              |
| ------------------------------ | -------------------------------- |
| Create a window                | `` ` `` then `c`                 |
| Next / previous window         | `` ` `` then `n` / `p`           |
| Quickly repeat next / previous | `` ` `` then `Ctrl-N` / `Ctrl-P` |
| Return to the last window      | `` ` `` then `l`                 |
| Choose from a window list      | `` ` `` then `w`                 |
| Select window 1 through 9      | `` ` `` then `1` through `9`     |
| Rename the current window      | `` ` `` then `,`                 |
| Close the current window       | `` ` `` then `&`                 |

Window numbering starts at 1 and is automatically compacted when a window is
removed. Titles normally update to show the active command and directory.

## Panes

| What you want                      | Key                               |
| ---------------------------------- | --------------------------------- |
| Split left and right               | `` ` `` then `%`                  |
| Split top and bottom               | `` ` `` then `"`                  |
| Move to another pane               | `` ` `` then an arrow key         |
| Cycle through panes                | `` ` `` then `o`                  |
| Show pane numbers, then choose one | `` ` `` then `q`, then its number |
| Zoom or unzoom the current pane    | `` ` `` then `z`                  |
| Close the current pane             | `` ` `` then `x`                  |
| Cycle through layouts              | `` ` `` then `Space`              |
| Swap with the previous / next pane | `` ` `` then `{` / `}`            |
| Resize by one cell                 | `` ` `` then `Ctrl` + arrow key   |
| Resize by five cells               | `` ` `` then `Alt` + arrow key    |

If the terminal consumes an `Alt` shortcut, use command mode instead: press
`` ` `` then `:`, type `resize-pane -L 5` (or `-R`, `-U`, `-D`), and press
`Enter`.

## Scroll and Copy

The setup retains 20,000 lines per pane and uses vi keys in copy mode.

1. Press `` ` `` then `[` to enter copy mode.
2. Move with `h` `j` `k` `l`, `Ctrl-B`, `Ctrl-F`, `g`, or `G`.
3. Press `/`, type text, and press `Enter` to search forward. Use `n` to repeat.
4. Press `Space` to start selecting, move to the end, then press `Enter` to copy
   and leave copy mode. Press `v` while selecting to toggle a rectangular block.
5. Press `` ` `` then `]` to paste the latest tmux buffer.

Press `q` or `Esc` to leave copy mode without copying. Mouse mode is off by
default; turn it on when convenient with `` ` `` then `m`. With mouse mode on,
the wheel scrolls and panes can be selected or resized with the mouse. Turn it
off with `` ` `` then capital `M` so the terminal handles mouse selection again.

The configuration enables OSC 52 clipboard integration. Copying from tmux can
therefore reach the desktop clipboard when the terminal supports and permits
OSC 52; otherwise the text remains available in tmux's own paste buffer.

## Save and Restore

`tmux-resurrect` saves session names, windows, panes, working directories, and
layouts. Saving is manual in this setup.

| What you want                      | Key                   |
| ---------------------------------- | --------------------- |
| Save the current tmux environment  | `` ` `` then `Ctrl-S` |
| Restore the last saved environment | `` ` `` then `Ctrl-R` |

Save before restarting or shutting down. Restore after starting a fresh tmux
server. The plugin restores selected programs only; it is not a replacement for
saving editor files, database data, or other application state.

## Configuration and Plugins

Put private or machine-specific settings in `~/.tmux.local.conf`. The shared
`~/.tmux.conf` loads this file when it exists, so personal changes survive the
next installer run.

Example `~/.tmux.local.conf`:

```tmux
# Use a shorter left status area on this machine.
set -g status-left '#S '

# Open new panes in the current pane's directory.
bind c new-window -c '#{pane_current_path}'
bind '%' split-window -h -c '#{pane_current_path}'
bind '"' split-window -v -c '#{pane_current_path}'
```

Reload configuration inside tmux with `` ` `` then capital `R`, or run:

```sh
tmux source-file ~/.tmux.conf
```

TPM maintenance shortcuts:

| What you want                       | Key                  |
| ----------------------------------- | -------------------- |
| Install missing plugins             | `` ` `` then `I`     |
| Update plugins                      | `` ` `` then `U`     |
| Remove plugins no longer configured | `` ` `` then `Alt-U` |

The installed plugins are TPM, tmux-resurrect, tmux-sensible, and the
network-enabled `tmux-mem-cpu-load` status monitor.

## Troubleshooting

- **A shortcut does nothing:** press and release backtick before the command;
  this setup does not use the default `Ctrl-B` prefix.
- **Plugins or system stats are missing:** press `` ` `` then `I` and wait for
  TPM to finish. Confirm that `cmake`, `make`, and a C++ compiler are installed.
- **Changes do not appear:** reload with `` ` `` then `R`. Existing servers do
  not automatically reread `~/.tmux.conf`.
- **Colors look wrong:** ensure the outer terminal supports 256 colors and true
  color. Inside tmux, check with `printf '%s\n' "$TERM"`.
- **Clipboard copy stays inside tmux:** enable OSC 52 access in the terminal, or
  use the terminal's own selection while mouse mode is off.
- **Nested tmux needs a literal backtick:** press backtick twice. The first is
  the outer prefix and the second is sent to the program inside the pane.
- **The installer reports an existing TPM path:** move the non-Git
  `~/.tmux/plugins/tpm` directory aside, then rerun the installer.
- **Need the old configuration:** recover it from the path printed by the
  installer under `~/.tmux-config-backup.XXXXXX`.

To see every active binding, run `tmux list-keys`. For details on a command, use
`man tmux` and search with `/command-name`.
