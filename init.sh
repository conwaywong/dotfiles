#!/bin/bash

debian_packages () {
        sudo apt-get update
        sudo apt-get upgrade -y
        sudo apt-get install -y \
            bat \
            jid \
            jq \
            meld \
            podman \
            stow \
            tidy \
            tmux \
            vim \
            zsh
}

if [ -f /etc/os-release ]; then
        . /etc/os-release # source release info
        case "$ID" in
        "debian"|"ubuntu")
                debian_packages
        ;;
        "redhat")
                echo "FEDORA!"
        ;;
        *)
                echo "Distribution $ID not supported."
                exit 1
        ;;
        esac
fi

# Install vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
mkdir -p $HOME/.vim/backup/

# Install prezto and make zsh default shell
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
chsh -s /bin/zsh

stow -t $HOME --dotfiles fonts git podman tmux vim zsh

# install tmux package manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

fc-cache -fv # load user fonts from .local/share/cache

zsh
