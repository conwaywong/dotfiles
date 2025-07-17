#!/bin/bash

debian_packages() {
  sudo apt-get update
  sudo apt-get upgrade -y
  sudo apt-get install -y \
    bat \
    build-essential \
    fd-find \
    jid \
    jq \
    meld \
    npm \
    perl \
    podman \
    python3-venv \
    ripgrep \
    silversearcher-ag \
    stow \
    tidy \
    tmux \
    universal-ctags \
    unzip \
    zip \
    zsh
}

if [ -f /etc/os-release ]; then
  . /etc/os-release # source release info
  case "$ID" in
  "debian" | "ubuntu")
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

mkdir -p $HOME/.local/bin

pushd $HOME

# Install tagged version of neovim.
wget https://github.com/neovim/neovim/releases/download/v0.11.1/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
rm nvim-linux-x86_64.tar.gz

# Install miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/.miniconda
rm Miniconda3-latest-Linux-x86_64.sh

# Install specific version of fzf
wget https://github.com/junegunn/fzf/releases/download/v0.64.0/fzf-0.64.0-linux_amd64.tar.gz
tar xf fzf-0.64.0-linux_amd64.tar.gz -C $HOME/.local/bin
rm fzf-0.64.0-linux_amd64.tar.gz

popd

# Install prezto and make zsh default shell
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
chsh -s /bin/zsh

stow --no-folding -t $HOME conda fonts git nvim podman tmux zsh

# install tmux package manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

fc-cache -fv # load user fonts from .local/share/cache

zsh

# disable Windows PATH in WSL
if [ -f /etc/wsl.conf ]; then
  echo "\n[interop]\nappendWindowsPath = false" | sudo tee -a /etc/wsl.conf
fi

npm config set prefix ~/.local
