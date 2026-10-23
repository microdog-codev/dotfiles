export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Detect OS type
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  export OS_TYPE="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  export OS_TYPE="macos"
elif [[ "$OSTYPE" == "cygwin" ]]; then
  export OS_TYPE="cygwin"
elif [[ "$OSTYPE" == "msys" ]]; then
  export OS_TYPE="msys"
elif [[ "$OSTYPE" == "win32" ]]; then
  export OS_TYPE="windows"
elif [[ "$OSTYPE" == "freebsd"* ]]; then
  export OS_TYPE="freebsd"
else
  export OS_TYPE="unknown"
fi

HISTSIZE=50000
SAVEHIST=500000

if command -v nvim &>/dev/null; then
    export EDITOR=nvim
elif command -v vim &>/dev/null; then
    export EDITOR=vim
elif command -v vi &>/dev/null; then
    export EDITOR=vi
else
    export EDITOR=nano
fi

### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit's installer chunk

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/z-a-rust \
    zdharma-continuum/z-a-as-monitor \
    zdharma-continuum/z-a-patch-dl \
    zdharma-continuum/z-a-bin-gem-node

#
# Theme
zinit ice from"gh-r" as"command" atload'eval "$(starship init zsh)"'
zinit load starship/starship

#
# Plugins

# zdharma-continuum/fast-syntax-highlighting
# zsh-users/zsh-completions
# zsh-users/zsh-autosuggestions
zinit wait lucid light-mode for \
  atinit"zicompinit; zicdreplay" \
      zdharma-continuum/fast-syntax-highlighting \
  atload"_zsh_autosuggest_start" \
      zsh-users/zsh-autosuggestions \
  blockf atpull'zinit creinstall -q .' \
      zsh-users/zsh-completions

# Avoid inverse-video visual highlighting that can hide the cursor on
# Gruvbox-like terminal themes, and disable the temporary paste overlay so it
# does not flatten syntax colors.
typeset -ga zle_highlight
zle_highlight=(
  ${${(@)zle_highlight:#region:*}:#paste:*}
  region:fg=#fabd2f,bold
  paste:none
)

# trapd00r/LS_COLORS
if [[ "$OS_TYPE" == "linux" ]]; then
  zinit ice atclone"dircolors -b LS_COLORS > clrs.zsh" \
      atpull'%atclone' pick"clrs.zsh" nocompile'!' \
      atload'zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"'
  zinit light trapd00r/LS_COLORS
fi

# jeffreytse/zsh-vi-mode
# Keep the plugin's default NEX readkey engine. With ZVM_READKEY_ENGINE_ZLE the
# surround text objects (ci", di", ca', ci(, ...) never execute: zvm_range_handler
# hands them back through ZVM_KEYS, which only the NEX handler (zle -U) consumes.
# The stale ZVM_KEYS then corrupts every later c/d/y keypress on the line.
function zvm_config() {
  ZVM_KEYTIMEOUT=0.03
  ZVM_ESCAPE_KEYTIMEOUT=0.01
}
function zvm_after_init() {
  bindkey '^[[A' history-beginning-search-backward
  bindkey '^[[B' history-beginning-search-forward
  bindkey '^P' history-beginning-search-backward
  bindkey '^N' history-beginning-search-forward

  # Work around upstream bracketed-paste corruption (jeffreytse/zsh-vi-mode
  # issues #353 and #238): when a paste arrives in chunks with gaps longer than
  # KEYTIMEOUT, ZLE ends the paste early and the leftover closing sequence is
  # read as keys; ESC leaves insert mode and vicmd's ~ flips the case of the
  # last character. Swallow the closing sequence whenever it reaches a keymap.
  zvm_swallow_bracketed_paste_end() { : }
  zle -N zvm_swallow_bracketed_paste_end
  bindkey -M viins '^[[201~' zvm_swallow_bracketed_paste_end
  bindkey -M vicmd '^[[201~' zvm_swallow_bracketed_paste_end
  bindkey -M visual '^[[201~' zvm_swallow_bracketed_paste_end
}
zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode

# OMZ Plugins
zinit snippet OMZ::lib/completion.zsh
zinit snippet OMZ::lib/history.zsh
zinit snippet OMZ::lib/key-bindings.zsh
zinit snippet OMZ::plugins/colored-man-pages/colored-man-pages.plugin.zsh

zinit ice lucid wait'1'
zinit snippet OMZ::plugins/common-aliases/common-aliases.plugin.zsh

zinit ice lucid wait='1'
zinit snippet OMZ::plugins/git/git.plugin.zsh

# junegunn/fzf - Linux only
if [[ "$OS_TYPE" == "linux" ]]; then
  zinit ice lucid as"command" from"gh-r" pick"fzf"
  zinit light junegunn/fzf
fi

zinit ice lucid wait atinit='export FZF_DEFAULT_COMMAND="fd --exclude .git"; export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND --no-ignore-vcs"'
zinit snippet OMZ::plugins/fzf/fzf.plugin.zsh

#
# Tools

# pctl
zinit ice wait"0" lucid
zinit light microdog/pctl
alias proxy="pctl --set"
alias noproxy="pctl --unset"

# sharkdp/fd
zinit ice wait"0" lucid as"command" from"gh-r" mv"fd* -> fd" pick"fd/fd"
zinit light sharkdp/fd
#
# ajeetdsouza/zoxide
zinit ice wait"1" lucid from"gh-r" as"command" pick"zoxide" \
  atload'unalias zi 2>/dev/null; eval "$(zoxide init zsh)"'
zinit light ajeetdsouza/zoxide

# BurntSushi/ripgrep - Linux only
if [[ "$OS_TYPE" == "linux" ]]; then
  zinit ice wait"1" lucid as"command" from"gh-r" mv"ripgrep* -> ripgrep" pick"ripgrep/rg"
  zinit light BurntSushi/ripgrep
fi

# sharkdp/bat
zinit ice wait"1" lucid as"command" from"gh-r" mv"bat* -> bat" pick"bat/bat"
zinit light sharkdp/bat

# eza-community(ogham/exa), replacement for ls
function _eza_alias() {
    # ls, the common ones I use a lot shortened for rapid fire usage
    alias ls='eza'
    alias l='eza -lg -F auto'     # long, show type, show group
    alias la='eza -lag -F auto'   # long, show almost all, show type, show group
    unalias lr
    alias lt='eza -s modified -lg -F auto'   # long, show type, show group
    alias ll='eza -l'      # long list
    alias ldot='eza -ld .*'
    unalias lS
    unalias lart
    unalias lrt

    unset -f _eza_alias
}
zinit ice wait"1" lucid from"gh-r" as"program" pick"eza" atload'_eza_alias'
zinit light eza-community/eza

# httpstat
zinit ice wait"2" lucid as"program" pick"httpstat"
zinit light b4b4r07/httpstat

# tldr
zinit ice wait"2" lucid as"program" pick"tldr"
zinit light raylee/tldr-sh-client

# gibo
zinit ice wait"2" lucid from"gh-r" as"program" pick"gibo" atload'eval "$(gibo completion zsh)"'
zinit light simonwhitaker/gibo

# jesseduffield/lazygit
zinit ice wait"2" lucid as"command" from"gh-r" pick"lazygit/lazygit"
zinit light jesseduffield/lazygit

# gitleaks/gitleaks
zinit ice wait"2" lucid from"gh-r" as"command" pick"gitleaks"
zinit light gitleaks/gitleaks

# direnv/direnv
zinit ice wait"2" lucid from"gh-r" as"command" extract mv"direnv* -> direnv" pick"direnv" \
  atclone'chmod +x direnv; ./direnv hook zsh > zhook.zsh' \
  atpull'%atclone' \
  src"zhook.zsh"
zinit light direnv/direnv

# iTerm2 shell integration
zinit ice wait"2" lucid as"program" pick"utilities/*"
zinit light gnachman/iTerm2-shell-integration

# aristocratos/btop - Linux only
if [[ "$OS_TYPE" == "linux" ]]; then
  zinit ice wait"2" lucid from"gh-r" as"program" pick"btop/bin/btop"
  zinit light aristocratos/btop
fi

# conda-incubator/conda-zsh-completion
zinit ice wait"2" lucid as"completion"
zinit light conda-incubator/conda-zsh-completion

# jdx/mise
# Freeze completion after updating usage so their tab-separated protocol stays compatible.
# Keep activation dynamic because its generated script snapshots PATH.
zinit ice wait"2" lucid from"gh-r" as"command" bpick"*.tar.gz" pick"mise/bin/mise" \
  atclone'./mise/bin/mise use -g usage@latest; ./mise/bin/mise completion zsh > _mise' \
  atpull'%atclone' \
  atload'eval "$("$PWD/mise/bin/mise" activate zsh)"'
zinit light jdx/mise

### End of Zinit's installer chunk

#
# Load extra configs
if [ -f ~/.zshrc.local ]; then
    source ~/.zshrc.local
fi

setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_all_dups   # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt inc_append_history     # append command to HISTFILE immediately after execution
#setopt share_history          # share command history data
setopt auto_cd                # cd by typing directory name if it's not a command
