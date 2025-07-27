#!/bin/bash

install_debian_packages() {
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update
  sudo apt-get upgrade -y
  sudo apt-get install -y \
    bashtop bat build-essential docker-ce docker-compose fd-find ffmpeg jid jq meld npm perl python3-venv \
    ripgrep silversearcher-ag stow tidy tmux universal-ctags unzip wl-clipboard wslu zip zsh

  sudo groupadd docker
  sudo usermod -aG docker $USER
}

install_fedora_packages() {
  sudo dnf -y install dnf-plugins-core
  sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

  sudo dnf update -y
  sudo dnf install -y \
    bashtop bat @development-tools docker-ce docker-compose fd-find ffmpeg jq meld npm perl python3-virtualenv \
    ripgrep the_silver_searcher stow tidy tmux universal-ctags unzip xclip zip zsh

  sudo groupadd docker
  sudo usermod -aG docker $USER
  sudo systemctl enable docker
  sudo systemctl start docker
}

if [ -f /etc/os-release ]; then
  . /etc/os-release
  case "$ID" in
  "debian" | "ubuntu")
    install_debian_packages
    ;;
  "fedora")
    install_fedora_packages
    ;;
  *)
    echo "Distribution $ID not supported."
    exit 1
    ;;
  esac
fi

mkdir -p $HOME/.local/bin

pushd $HOME

# Install Neovim
wget https://github.com/neovim/neovim/releases/download/v0.11.1/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
rm nvim-linux-x86_64.tar.gz

# Install Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/.miniconda
rm Miniconda3-latest-Linux-x86_64.sh

# Install Google Chrome
if [[ "$ID" == "debian" || "$ID" == "ubuntu" ]]; then
  wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo apt install -y ./google-chrome-stable_current_amd64.deb
  rm google-chrome-stable_current_amd64.deb
else
  wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
  sudo dnf install -y ./google-chrome-stable_current_x86_64.rpm
  rm google-chrome-stable_current_x86_64.rpm
fi

# Install specific version of fzf
wget https://github.com/junegunn/fzf/releases/download/v0.64.0/fzf-0.64.0-linux_amd64.tar.gz
tar xf fzf-0.64.0-linux_amd64.tar.gz -C $HOME/.local/bin
rm fzf-0.64.0-linux_amd64.tar.gz

# Install Lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
install lazygit -D -t $HOME/.local/bin
rm -rf lazygit lazygit.tar.gz

# Install Zoxide
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

popd

# Install Prezto and make Zsh the default shell
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
git clone https://github.com/conda-incubator/conda-zsh-completion.git "${ZDOTDIR:-$HOME}/.zprezto/contrib/conda-zsh-completion"
chsh -s /bin/zsh

stow --no-folding -t $HOME conda fonts git nvim podman prettier tmux zsh

# Install Tmux Plugin Manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

fc-cache -fv # Load user fonts from .local/share/cache

mkdir -p ~/.docker/completions
docker completion zsh >~/.docker/completions/_docker

# WSL-specific configuration
if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
  sudo touch /etc/wsl.conf
  echo -e "\n[interop]\nappendWindowsPath = false" | sudo tee -a /etc/wsl.conf
  cd $HOME/.local/bin
  ln -s /mnt/c/WINDOWS/system32/cmd.exe cmd.exe
  cd -
fi

npm config set prefix ~/.local

# Start a new Zsh shell
zsh
