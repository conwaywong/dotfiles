#!/bin/bash

debian_packages () {
        sudo add-apt-repository ppa:neovim-ppa/unstable -y # get latest neovim stable releases
        sudo apt-get update
        sudo apt-get upgrade -y
        sudo apt-get install -y \
            bat \
            fd-find \
            jid \
            jq \
            meld \
            neovim \
            podman \
            ripgrep \
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

# Install miniconda
pushd $HOME
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda3
rm Miniconda3-latest-Linux-x86_64.sh
popd

# Install vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
mkdir -p $HOME/.vim/backup/

# Install prezto and make zsh default shell
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
chsh -s /bin/zsh

stow --no-folding -t $HOME --dotfiles fonts git nvim podman tmux vim zsh

# install tmux package manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

fc-cache -fv # load user fonts from .local/share/cache

zsh
