# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc. 
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export EDITOR=nvim
export VISUAL=nvim

export REGISTRY_AUTH_FILE=$HOME/.config/containers/auth.json

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

__conda_setup=$($HOME/.miniconda/bin/conda shell.zsh hook 2> /dev/null)
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/.miniconda/etc/profile.d/conda.sh" ]; then
        . "$HOME/.miniconda/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/.miniconda/bin:$PATH"
    fi
fi
unset __conda_setup

# init zoxide
eval "$(zoxide init zsh)"

# leave at end
[ -f ~/.zsh_aliases ] && source ~/.zsh_aliases
