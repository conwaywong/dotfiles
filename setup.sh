#!/bin/bash

# WSL/Linux Development Environment Setup Script
# This script installs and configures a complete development environment
# for WSL2 or native Linux systems (Ubuntu/Debian/Fedora)

set -euo pipefail # Exit on error, undefined vars, pipe failures

# =============================================================================
# Configuration Variables
# =============================================================================

readonly NVIDIA_TOOLKIT_VERSION="1.17.8-1"
readonly NEOVIM_VERSION="v0.11.1"
readonly FZF_VERSION="v0.65.1"
readonly NERD_FONTS_VERSION="v3.4.0"

# =============================================================================
# Utility Functions
# =============================================================================

log() {
  echo -e "\033[32m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m" >&2
  echo -e "🔧 [$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
  echo -e "\033[32m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m" >&2
  echo >&2
}

error() {
  echo -e "\033[31m╔════════════════════════════════════════════════════════════════════════════╗\033[0m" >&2
  echo -e "❌ [$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
  echo -e "\033[31m╚════════════════════════════════════════════════════════════════════════════╝\033[0m" >&2
  echo >&2
  exit 1
}

nvidia_exists() {
  [ -f "/mnt/c/Windows/System32/nvidia-smi.exe" ]
}

is_wsl() {
  # Debian 13 has observed to create WSLInterop-late file, so check for glob
  ls -d -- /proc/sys/fs/binfmt_misc/WSLInterop* >/dev/null 2>&1
  return $?
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# =============================================================================
# Package Installation Functions
# =============================================================================

install_docker_debian() {
  log "Installing Docker for Debian/Ubuntu..."

  # Add Docker's official GPG key and repository
  sudo install -m 0755 -d /etc/apt/keyrings

  # Determine the correct repository URL based on distribution
  if grep -q "ubuntu" /etc/os-release; then
    REPO_URL="https://download.docker.com/linux/ubuntu"
    log "Detected Ubuntu - using Ubuntu repository"
  else
    REPO_URL="https://download.docker.com/linux/debian"
    log "Detected Debian - using Debian repository"
  fi

  sudo curl -fsSL ${REPO_URL}/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] ${REPO_URL} $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update

  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Configure Docker group
  sudo groupadd docker 2>/dev/null || true # Don't fail if group exists
  sudo usermod -aG docker "$USER"
}

install_nvidia_ubuntu() {
  log "Installing NVIDIA CUDA toolkit for Debian/Ubuntu..."
  wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.1-1_all.deb
  sudo dpkg -i cuda-keyring_1.1-1_all.deb
  sudo apt-get update
  sudo apt-get -y install cuda-toolkit-13-0 nvtop
  rm -f cuda-keyring_1.1-1_all.deb

  # Install NVIDIA Container Toolkit
  install_nvidia_container_toolkit_debian
}

install_nvidia_container_toolkit_debian() {
  log "Installing NVIDIA Container Toolkit for Debian/Ubuntu..."

  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey |
    sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

  curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list |
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' |
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

  sudo apt-get update
  sudo apt-get install -y \
    "nvidia-container-toolkit=${NVIDIA_TOOLKIT_VERSION}" \
    "nvidia-container-toolkit-base=${NVIDIA_TOOLKIT_VERSION}" \
    "libnvidia-container-tools=${NVIDIA_TOOLKIT_VERSION}" \
    "libnvidia-container1=${NVIDIA_TOOLKIT_VERSION}"

  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker
}

install_ubuntu_packages() {
  log "Installing packages for Ubuntu..."

  sudo apt-get update
  sudo apt-get upgrade -y

  # Install essential development packages
  sudo apt-get install -y \
    bat btop build-essential fd-find ffmpeg \
    google-perftools jid jq meld npm perl python3-venv ripgrep \
    silversearcher-ag stow tidy tldr tmux universal-ctags unzip \
    wl-clipboard zip zsh

  # Remove unwanted packages
  sudo apt autoremove -y --purge apport cups snapd unattended-upgrades wsl-pro-service || true

  install_docker_debian

  # Install NVIDIA support if available
  if nvidia_exists; then
    install_nvidia_ubuntu
  fi
}

install_debian_packages() {
  log "Installing packages for Debian..."

  sudo apt-get update
  sudo apt-get upgrade -y

  # Install essential development packages
  sudo apt-get install -y \
    bat btop build-essential fd-find ffmpeg \
    google-perftools gpg jid jq meld npm perl pkexec polkitd python3-venv ripgrep \
    silversearcher-ag stow tidy tldr-py tmux universal-ctags unzip \
    wl-clipboard zip zsh

  install_docker_debian

  # Install NVIDIA support if available
  if nvidia_exists; then
    install_nvidia_ubuntu # For now. use Ubuntu and Debian use the same WSL CUDA packages
  fi
}

install_docker_fedora() {
  log "Installing Docker for Fedora..."

  sudo dnf -y install dnf-plugins-core
  sudo dnf-3 -y config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
  sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Configure Docker
  sudo groupadd docker 2>/dev/null || true
  sudo usermod -aG docker "$USER"
  sudo systemctl enable docker
  sudo systemctl start docker
}

install_nvidia_fedora() {
  log "Installing NVIDIA CUDA toolkit for Fedora..."

  # Install CUDA toolkit
  sudo dnf -y config-manager addrepo --from-repofile https://developer.download.nvidia.com/compute/cuda/repos/fedora42/x86_64/cuda-fedora42.repo
  sudo dnf clean all
  sudo dnf -y install cuda-toolkit-13-0 nvtop

  # Install NVIDIA Container Toolkit
  install_nvidia_container_toolkit_fedora
}

install_nvidia_container_toolkit_fedora() {
  log "Installing NVIDIA Container Toolkit for Fedora..."

  curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo |
    sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

  sudo dnf install -y \
    "nvidia-container-toolkit-${NVIDIA_TOOLKIT_VERSION}" \
    "nvidia-container-toolkit-base-${NVIDIA_TOOLKIT_VERSION}" \
    "libnvidia-container-tools-${NVIDIA_TOOLKIT_VERSION}" \
    "libnvidia-container1-${NVIDIA_TOOLKIT_VERSION}"

  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker
}

install_fedora_packages() {
  log "Installing packages for Fedora..."

  sudo dnf update -y

  # Install essential development packages
  sudo dnf install -y \
    bat btop ctags @development-tools fd-find ffmpeg google-perftools hostname \
    jq meld npm perl python3-virtualenv ripgrep \
    the_silver_searcher stow tidy tldr tmux unzip \
    wl-clipboard zip zsh

  install_docker_fedora

  # Remove unwanted packages
  sudo dnf remove -y --noautoremove snapd unattended-upgrades || true

  # Install NVIDIA support if available
  if nvidia_exists; then
    install_nvidia_fedora
  fi
}

# =============================================================================
# Application Installation Functions
# =============================================================================

install_neovim() {
  log "Installing Neovim ${NEOVIM_VERSION}..."

  local nvim_archive="nvim-linux-x86_64.tar.gz"
  wget "https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/${nvim_archive}"
  sudo rm -rf /opt/nvim
  sudo tar -C /opt -xzf "${nvim_archive}"
  rm "${nvim_archive}"
}

install_uv() {
  log "Installing uv..."

  local uv_installer="install.sh"
  wget "https://astral.sh/uv/install.sh"
  bash "${uv_installer}"
  rm "${uv_installer}"
}

install_chrome() {
  log "Installing Google Chrome..."

  if [[ "$ID" == "debian" || "$ID" == "ubuntu" ]]; then
    local chrome_deb="google-chrome-stable_current_amd64.deb"
    wget "https://dl.google.com/linux/direct/${chrome_deb}"
    sudo apt install -y "./${chrome_deb}"
    rm "${chrome_deb}"
  else
    local chrome_rpm="google-chrome-stable_current_x86_64.rpm"
    wget "https://dl.google.com/linux/direct/${chrome_rpm}"
    sudo dnf install -y "./${chrome_rpm}"
    rm "${chrome_rpm}"
  fi
}

install_fzf() {
  log "Installing fzf ${FZF_VERSION}..."

  local fzf_version="${FZF_VERSION#v}" # Remove 'v' prefix
  local fzf_archive="fzf-${fzf_version}-linux_amd64.tar.gz"
  wget "https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/${fzf_archive}"
  tar xf "${fzf_archive}" -C "$HOME/.local/bin"
  rm "${fzf_archive}"
}

install_lazygit() {
  log "Installing Lazygit..."

  local lazygit_version
  lazygit_version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" |
    grep -Po '"tag_name": *"v\K[^"]*')

  local lazygit_archive="lazygit_${lazygit_version}_Linux_x86_64.tar.gz"
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${lazygit_version}/${lazygit_archive}"
  tar xf lazygit.tar.gz lazygit
  install lazygit -D -t "$HOME/.local/bin"
  rm -rf lazygit lazygit.tar.gz
}

install_zoxide() {
  log "Installing Zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

# =============================================================================
# Configuration Functions
# =============================================================================

setup_shell_environment() {
  log "Setting up shell environment..."

  # Install Prezto
  if [ ! -d "${ZDOTDIR:-$HOME}/.zprezto" ]; then
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
  fi

  # Change default shell to zsh
  if [ "$SHELL" != "/bin/zsh" ]; then
    chsh -s /bin/zsh
  fi
  zsh

  # create default venv
  $HOME/.local/bin/uv venv --prompt base
}

setup_dotfiles() {
  log "Setting up dotfiles..."
  stow --no-folding -t "$HOME" fonts git nvim podman prettier tmux zsh
}

setup_tmux() {
  log "Setting up Tmux..."

  if [ ! -d ~/.tmux/plugins/tpm ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi
}

setup_fonts() {
  log "Setting up fonts..."

  # Load user fonts
  # fc-cache -fv

  # Install Nerd Font symbols
  sudo wget -P /usr/share/fontconfig/conf.avail/ \
    https://github.com/ryanoasis/nerd-fonts/raw/refs/heads/master/10-nerd-font-symbols.conf

  sudo ln -sf /usr/share/fontconfig/conf.avail/10-nerd-font-symbols.conf \
    /etc/fonts/conf.d/10-nerd-font-symbols.conf

  local nerd_fonts_zip="NerdFontsSymbolsOnly.zip"
  wget "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/${nerd_fonts_zip}"
  sudo mkdir -p /usr/share/fonts/nerdfonts
  sudo unzip "${nerd_fonts_zip}" -d /usr/share/fonts/nerdfonts/
  rm -f "${nerd_fonts_zip}"
  sudo fc-cache -f -v
}

setup_docker_completion() {
  log "Setting up Docker completion..."

  mkdir -p ~/.docker/completions
  if command_exists docker; then
    docker completion zsh >~/.docker/completions/_docker
  fi
}

setup_systemd() {
  log "Setting up systemd user services..."
  # Enable linger to support user-scoped systemd services
  loginctl enable-linger "$USER"
}

setup_wsl_config() {
  log "Configuring WSL-specific settings..."

  # Configure WSL settings
  sudo touch /etc/wsl.conf
  if ! grep -q "\[interop\]" /etc/wsl.conf; then
    echo -e "\n[interop]\nappendWindowsPath = false\n" | sudo tee -a /etc/wsl.conf
  fi
  if ! grep -q "\[network\]" /etc/wsl.conf; then
    echo -e "\n[network]\ngenerateResolvConf = false\n" | sudo tee -a /etc/wsl.conf
  fi

  # Configure DNS
  if [ -L /etc/resolv.conf ]; then
    sudo unlink /etc/resolv.conf 2>/dev/null || true
    echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
    sudo chattr +i /etc/resolv.conf
  fi

  # Link Windows cmd.exe
  if [ ! -f "$HOME/.local/bin/cmd.exe" ]; then
    mkdir -p "$HOME/.local/bin"
    ln -s /mnt/c/WINDOWS/system32/cmd.exe "$HOME/.local/bin/cmd.exe"
  fi

  # Set BROWSER env variable (https://superuser.com/a/1266038)
  touch "$HOME/.zshenv_ext"
  echo "export BROWSER='/mnt/c/Windows/explorer.exe'" >>"$HOME/.zshenv_ext"
}

setup_npm() {
  log "Configuring npm..."
  npm config set prefix ~/.local
}

# =============================================================================
# Main Installation Flow
# =============================================================================

main() {
  log "Starting development environment setup..."

  # Detect and install packages for the current distribution
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
    "debian")
      install_debian_packages
      ;;
    "ubuntu")
      install_ubuntu_packages
      ;;
    "fedora")
      install_fedora_packages
      ;;
    *)
      error "Distribution $ID not supported. Supported: debian, ubuntu, fedora"
      ;;
    esac
  else
    error "/etc/os-release not found. Cannot determine distribution."
  fi

  # Create local bin directory
  mkdir -p "$HOME/.local/bin"

  # Change to home directory for installations
  pushd "$HOME" || error "Cannot change to home directory"

  # Install applications
  install_neovim
  install_uv
  install_chrome
  install_fzf
  install_lazygit
  install_zoxide

  # Return to original directory
  popd || true

  # Setup configurations
  setup_shell_environment
  setup_dotfiles
  setup_tmux
  setup_fonts
  setup_docker_completion
  setup_systemd

  # WSL-specific configuration
  if is_wsl; then
    setup_wsl_config
  fi

  # Final configurations
  setup_npm

  log "Setup completed successfully!"
  log "Please restart your terminal or run 'exec zsh' to use the new shell configuration."

  # Start zsh if not already running
  if [ "$0" != "zsh" ]; then
    exec zsh
  fi
}

# =============================================================================
# Script Entry Point
# =============================================================================

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
