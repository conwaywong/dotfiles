# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc. 
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

export EDITOR=nvim
export VISUAL=nvim

export REGISTRY_AUTH_FILE=$HOME/.config/containers/auth.json

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Check if the current directory contains a .venv folder
if [ -d "$HOME/.venv" ]; then
    # If .venv exists in the current directory, activate it
    source "$HOME/.venv/bin/activate"
fi

eval "$(uv generate-shell-completion zsh)"
eval "$(uvx --generate-shell-completion zsh)"

# init zoxide
eval "$(zoxide init zsh)"

# docker autocomplete
FPATH="$HOME/.docker/completions:$FPATH"
autoload -Uz compinit
compinit

# leave at end
[ -f ~/.zsh_aliases ] && source ~/.zsh_aliases
