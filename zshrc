# Portable preferences from this Mac; work state stays on the company device.
[[ -o interactive ]] || return
setopt interactivecomments
typeset -U path fpath
path=("$HOME/.local/bin" $path)
for _dotfiles_prefix in /opt/homebrew /usr/local; do
  [[ -d "$_dotfiles_prefix/share/zsh/site-functions" ]] &&
    fpath=("$_dotfiles_prefix/share/zsh/site-functions" $fpath)
done
unset _dotfiles_prefix
if [[ -d "${DOTFILES_PURE_SITE_FUNCTIONS:-}" ]]; then
  fpath=("$DOTFILES_PURE_SITE_FUNCTIONS" $fpath)
fi

# Never load a personal override from the repository.
[[ -r "$HOME/.config/dotfiles/work.local.zsh" ]] &&
  source "$HOME/.config/dotfiles/work.local.zsh"

# Reassert work namespaces after local settings and inherited environments.
export DOTFILES_PROFILE=work
export XDG_CONFIG_HOME="$HOME/.config"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL EMAIL
unset GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS
export XDG_DATA_HOME="$HOME/.local/share/work"
export XDG_STATE_HOME="$HOME/.local/state/work"
export XDG_CACHE_HOME="$HOME/.cache/work"
export ATUIN_CONFIG_DIR="$HOME/.config/atuin-work"
export NVIM_APPNAME=nvim-work
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=10000
SAVEHIST=10000
umask 077
mkdir -p "$XDG_STATE_HOME/zsh" "$XDG_DATA_HOME/atuin" "$XDG_CACHE_HOME"
setopt appendhistory histignorespace histignoredups

export CLICOLOR=1
export LSCOLORS=Gxfxcxdxbxegedabagacad
export HEADROOM_TELEMETRY=off
PURE_GIT_PULL=0
if [[ -z "$SSH_CONNECTION" ]] && (( $+commands[nvim] )); then
  export EDITOR=nvim
else
  export EDITOR=vi
fi
export VISUAL="$EDITOR"
if (( $+commands[nvim] )); then
  alias vim=nvim vi=nvim
fi
if [[ "$OSTYPE" == darwin* ]]; then
  alias ls='ls -laGF'
else
  alias ls='ls -laF --color=auto'
fi
alias tree='tree -a'
if [[ -x /usr/local/microsoft/powershell/7/pwsh ]]; then
  alias powershell=/usr/local/microsoft/powershell/7/pwsh
fi

# Explicit maintenance only; opening a terminal never updates packages.
bup() {
  (( $+commands[brew] )) || { print -u2 'Homebrew is not installed.'; return 1; }
  if command pgrep -x brew >/dev/null; then
    print -u2 'Another Homebrew command is running.'
    return 1
  fi
  command brew update && command brew upgrade && command brew doctor
}

autoload -Uz compinit promptinit
compinit -d "$XDG_CACHE_HOME/zcompdump"
promptinit
if (( $+functions[prompt_pure_setup] )); then
  zstyle :prompt:pure:path color cyan
  zstyle :prompt:pure:git:branch color magenta
  PURE_CMD_MAX_EXEC_TIME=5
  prompt pure
else
  PROMPT='%n@%m %1~ %# '
fi

if (( $+commands[atuin] )); then
  eval "$(command atuin init zsh)"
fi
