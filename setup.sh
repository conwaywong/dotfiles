#!/bin/bash

# WSL/Linux Development Environment Setup Script
# This script installs and configures a complete development environment
# for WSL2 or native Linux systems (Ubuntu/Debian/Fedora/Arch/openSUSE)

set -eo pipefail # Exit on error and pipe failures

# =============================================================================
# Configuration Variables
# =============================================================================

readonly NVIDIA_TOOLKIT_VERSION="1.20.0-1"
readonly CUDA_TOOLKIT_VERSION="13"
readonly NEOVIM_VERSION="v0.12.5"
readonly FZF_VERSION="v0.74.3"
readonly NERD_FONTS_VERSION="v3.5.1"
readonly LAZYGIT_VERSION="v0.64.1"
readonly ZOXIDE_VERSION="v0.10.0"
readonly UV_VERSION="0.12.8"
readonly MINICONDA_VERSION="py313_26.7.1-1"
readonly PREZTO_COMMIT="cff2d01871425b1b80710f8ec6a475c5a53145b4"
readonly CONDA_ZSH_COMPLETION_COMMIT="632655aab6e147b90f75cf3d195ae2b48e7beec9"
readonly TPM_COMMIT="e261deb1b47614eed3400089ce7197dc68acc4eb"

DRY_RUN=false
INSTALL_DOCKER=true
INSTALL_CHROME=true
RUN_SYSTEM_UPGRADE=true
REMOVE_UNWANTED=false
CONFIGURE_WSL_DNS=false

usage() {
  cat <<'EOF'
Usage: ./setup.sh [options]

Options:
  --dry-run              Show the selected operations without changing the system
  --no-docker            Skip Docker installation and configuration
  --no-chrome            Skip Google Chrome installation
  --no-system-upgrade    Install packages without upgrading the whole system
  --remove-unwanted      Remove optional packages such as Snap, CUPS, and apport
  --configure-wsl-dns    Replace WSL resolv.conf with a fixed 8.8.8.8 configuration
  --no-nvidia            Skip CUDA and NVIDIA Container Toolkit installation
  -h, --help             Show this help
EOF
}

parse_args() {
  while (($#)); do
    case "$1" in
    --dry-run) DRY_RUN=true ;;
    --no-docker) INSTALL_DOCKER=false ;;
    --no-chrome) INSTALL_CHROME=false ;;
    --no-system-upgrade) RUN_SYSTEM_UPGRADE=false ;;
    --remove-unwanted) REMOVE_UNWANTED=true ;;
    --configure-wsl-dns) CONFIGURE_WSL_DNS=true ;;
    --no-nvidia) NVIDIA_SKIP=true ;;
    -h | --help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
  done
}

configure_architecture() {
  case "$(uname -m)" in
  x86_64 | amd64)
    ARCH="x86_64"; DEB_ARCH="amd64"; FZF_ARCH="amd64"; RUST_ARCH="x86_64"
    ;;
  aarch64 | arm64)
    ARCH="arm64"; DEB_ARCH="arm64"; FZF_ARCH="arm64"; RUST_ARCH="aarch64"
    ;;
  *) error "Unsupported architecture: $(uname -m). Supported: x86_64, arm64" ;;
  esac
}

sha_for() {
  local application="$1"
  case "${application}:${ARCH}" in
  neovim:x86_64) echo "bce0f56eda1f1b1db6eee8f4133d7a38813ea07933837dd1777411ca384c6875" ;;
  neovim:arm64) echo "1aa5ca085249580ae0f91eb14f27ec0919773ff2d99a163d03f3d6c21ac29725" ;;
  fzf:x86_64) echo "3501a595e4b5c40a6b047340a0e8f805c46fd4e61ef95ef8a136ba8c61cf6f22" ;;
  fzf:arm64) echo "4a17a17b46bd0c4873e995533de508995c11572c0be0664a5dbcf13f60463046" ;;
  lazygit:x86_64) echo "f8ea237c41f194cd799b48505518bfdaae4edf5a2ad6bd3d898e939785ee4532" ;;
  lazygit:arm64) echo "8b7ca3b344e60340ad1f89f29b9868ee39bcaba5bb92ee818bbe65476bb8b6e7" ;;
  zoxide:x86_64) echo "2d93385b99f3e82cf2701609a1bffcad863fbeb75aa3fe7eb6be4d29be68b1ae" ;;
  zoxide:arm64) echo "f1f16c5d6298d63dee467eedea1cdcd8490e43e493bea43acd416dc9033ef641" ;;
  uv:x86_64) echo "2e2b37e9811e17675a9e70bed5e1a58fc8c0388be63d751d72cc735188c149ff" ;;
  uv:arm64) echo "ba8661f4fd207c8e94814191598e619b355ac10d5014e851e21eb800f9ef2b00" ;;
  nerd-fonts:*) echo "fdca3682534f6f65e1ccb2345b0362ccf67d9b8eca7c8025330946e93e2473bc" ;;
  nerd-fonts-config:*) echo "883f3ea0ca0874c567d9414be319de7a54d64f4a30aaa87f2ad4066da1687c07" ;;
  miniconda:x86_64) echo "c26cbbd996d5ada0bec054b49a37fab690e2f91125701e458df6cca73da9482b" ;;
  miniconda:arm64) echo "669e8f11248e97473ff058d97eb02b6c8e67f6c853e230f7a88cce95303c9fce" ;;
  *) error "No checksum configured for ${application} on ${ARCH}" ;;
  esac
}

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
  [ "$ARCH" = x86_64 ] && [ -z "${NVIDIA_SKIP:-}" ] &&
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

download_and_verify() {
  local url="$1" output="$2" checksum="$3"
  curl --fail --location --retry 3 --retry-all-errors --output "$output" "$url"
  printf '%s  %s\n' "$checksum" "$output" | sha256sum --check --status ||
    error "Checksum verification failed for $output"
}

clone_pinned() {
  local repository="$1" destination="$2" commit="$3" recursive="${4:-false}"
  git clone --filter=blob:none "$repository" "$destination"
  git -C "$destination" checkout --detach "$commit"
  if [ "$recursive" = true ]; then
    git -C "$destination" submodule update --init --recursive
  fi
}

print_dry_run() {
  cat <<EOF
Dry run: no changes will be made.
Distribution: ${PRETTY_NAME:-$ID}
Architecture: $ARCH
Docker: $INSTALL_DOCKER
Chrome: $INSTALL_CHROME
System upgrade: $RUN_SYSTEM_UPGRADE
Remove optional packages: $REMOVE_UNWANTED
Configure fixed WSL DNS: $CONFIGURE_WSL_DNS
NVIDIA/CUDA: $([ -z "${NVIDIA_SKIP:-}" ] && echo auto-detect || echo disabled)
EOF
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

  # shellcheck source=/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] ${REPO_URL} $(. /etc/os-release && echo "${DEBIAN_CODENAME:-${UBUNTU_CODENAME:-$VERSION_CODENAME}}") stable" |
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
  sudo apt-get -y install "cuda-toolkit-${CUDA_TOOLKIT_VERSION}" nvtop
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

  if [ "$INSTALL_DOCKER" = true ]; then
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
  fi
}

install_ubuntu_packages() {
  log "Installing packages for Ubuntu..."

  sudo apt-get update
  if [ "$RUN_SYSTEM_UPGRADE" = true ]; then sudo apt-get upgrade -y; fi

  # Install essential development packages
  sudo apt-get install -y \
    bat btop build-essential fd-find ffmpeg \
    jid jq libgoogle-perftools-dev meld npm perl python3-venv ripgrep \
    silversearcher-ag stow tidy tldr-py tmux tree-sitter-cli universal-ctags unzip \
    wget wl-clipboard zip zsh

  # Remove unwanted packages
  if [ "$REMOVE_UNWANTED" = true ]; then
    sudo apt autoremove -y --purge apport cups snapd unattended-upgrades wsl-pro-service || true
  fi

  if [ "$INSTALL_DOCKER" = true ]; then install_docker_debian; fi

  # Install NVIDIA support if available
  if nvidia_exists; then
    install_nvidia_ubuntu
  fi
}

install_debian_packages() {
  log "Installing packages for Debian..."

  sudo apt-get update
  if [ "$RUN_SYSTEM_UPGRADE" = true ]; then sudo apt-get upgrade -y; fi

  # Install essential development packages
  sudo apt-get install -y \
    bat btop build-essential fd-find ffmpeg \
    google-perftools gpg jid jq meld npm perl pkexec polkitd python3-venv ripgrep \
    silversearcher-ag stow tidy tldr-py tmux tree-sitter-cli universal-ctags unzip \
    wget wl-clipboard zip zsh

  if [ "$INSTALL_DOCKER" = true ]; then install_docker_debian; fi

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

  # Detect Fedora version for the correct repo URL
  local fedora_version
  # shellcheck source=/dev/null
  fedora_version=$(. /etc/os-release && echo "$VERSION_ID")

  # Install CUDA toolkit
  sudo dnf -y config-manager addrepo --from-repofile "https://developer.download.nvidia.com/compute/cuda/repos/fedora${fedora_version}/x86_64/cuda-fedora${fedora_version}.repo"
  sudo dnf clean all
  sudo dnf -y install "cuda-toolkit-${CUDA_TOOLKIT_VERSION}" nvtop

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

  if [ "$INSTALL_DOCKER" = true ]; then
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
  fi
}

install_fedora_packages() {
  log "Installing packages for Fedora..."

  if [ "$RUN_SYSTEM_UPGRADE" = true ]; then sudo dnf update -y; fi

  # Install essential development packages
  sudo dnf install -y \
    bat btop ctags @development-tools e2fsprogs fd-find ffmpeg gperftools hostname \
    jq meld npm perl python3-virtualenv ripgrep \
    the_silver_searcher stow tidy tldr tmux tree-sitter-cli unzip \
    wget wl-clipboard zip zsh

  if [ "$INSTALL_DOCKER" = true ]; then install_docker_fedora; fi

  # Remove unwanted packages
  if [ "$REMOVE_UNWANTED" = true ]; then
    sudo dnf remove -y --noautoremove snapd unattended-upgrades || true
  fi

  # Install NVIDIA support if available
  if nvidia_exists; then
    install_nvidia_fedora
  fi
}

install_docker_arch() {
  log "Installing Docker for Arch Linux..."

  sudo pacman -S --noconfirm --needed docker docker-buildx docker-compose

  # Configure Docker group
  sudo groupadd docker 2>/dev/null || true
  sudo usermod -aG docker "$USER"
  sudo systemctl enable docker
  sudo systemctl start docker
}

install_nvidia_container_toolkit_arch() {
  log "Installing NVIDIA Container Toolkit for Arch Linux..."

  sudo pacman -S --noconfirm --needed nvidia-container-toolkit
  if [ "$INSTALL_DOCKER" = true ]; then
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
  fi
}

install_nvidia_arch() {
  log "Installing NVIDIA CUDA toolkit for Arch Linux..."

  sudo pacman -S --noconfirm --needed cuda nvtop
  install_nvidia_container_toolkit_arch
}

install_arch_packages() {
  log "Installing packages for Arch Linux..."

  if [ "$RUN_SYSTEM_UPGRADE" = true ]; then sudo pacman -Syu --noconfirm; fi

  sudo pacman -S --noconfirm --needed \
    bat btop base-devel ctags fd ffmpeg gperftools \
    jq meld npm perl python ripgrep \
    the_silver_searcher stow tidy tldr tmux unzip \
    wget wl-clipboard zip zsh

  if [ "$INSTALL_DOCKER" = true ]; then install_docker_arch; fi

  if nvidia_exists; then
    install_nvidia_arch
  fi
}

install_docker_opensuse() {
  log "Installing Docker for openSUSE..."

  sudo zypper addrepo --refresh https://download.docker.com/linux/sles/docker-ce.repo || true
  sudo zypper --gpg-auto-import-keys refresh
  sudo zypper install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Configure Docker group
  sudo groupadd docker 2>/dev/null || true
  sudo usermod -aG docker "$USER"
  sudo systemctl enable docker
  sudo systemctl start docker
}

install_nvidia_container_toolkit_opensuse() {
  log "Installing NVIDIA Container Toolkit for openSUSE..."

  curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo |
    sudo tee /etc/zypp/repos.d/nvidia-container-toolkit.repo

  sudo zypper --gpg-auto-import-keys refresh
  sudo zypper install -y \
    "nvidia-container-toolkit-${NVIDIA_TOOLKIT_VERSION}" \
    "nvidia-container-toolkit-base-${NVIDIA_TOOLKIT_VERSION}" \
    "libnvidia-container-tools-${NVIDIA_TOOLKIT_VERSION}" \
    "libnvidia-container1-${NVIDIA_TOOLKIT_VERSION}"

  if [ "$INSTALL_DOCKER" = true ]; then
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
  fi
}

install_nvidia_opensuse() {
  log "Installing NVIDIA CUDA toolkit for openSUSE..."

  sudo zypper addrepo --refresh \
    https://developer.download.nvidia.com/compute/cuda/repos/opensuse15/x86_64/cuda-opensuse15.repo
  sudo zypper --gpg-auto-import-keys refresh
  sudo zypper install -y "cuda-toolkit-${CUDA_TOOLKIT_VERSION}" nvtop

  install_nvidia_container_toolkit_opensuse
}

install_opensuse_packages() {
  log "Installing packages for openSUSE..."

  sudo zypper refresh
  if [ "$RUN_SYSTEM_UPGRADE" = true ]; then sudo zypper update -y; fi

  sudo zypper install -y \
    bat btop gcc gcc-c++ make ctags fd ffmpeg gperftools \
    jq meld npm perl python3 python3-virtualenv ripgrep \
    the_silver_searcher stow tidy tldr tmux unzip \
    wget wl-clipboard zip zsh

  if [ "$INSTALL_DOCKER" = true ]; then install_docker_opensuse; fi

  if nvidia_exists; then
    install_nvidia_opensuse
  fi
}

# =============================================================================
# Application Installation Functions
# =============================================================================

install_neovim() {
  log "Installing Neovim ${NEOVIM_VERSION}..."
  local nvim_dir="nvim-linux-${ARCH}"
  local nvim_archive="${nvim_dir}.tar.gz"
  download_and_verify \
    "https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/${nvim_archive}" \
    "$nvim_archive" "$(sha_for neovim)"
  sudo rm -rf /opt/nvim /opt/nvim-linux-x86_64 /opt/nvim-linux-arm64
  sudo tar -C /opt -xzf "$nvim_archive"
  sudo mv "/opt/${nvim_dir}" /opt/nvim
  rm "$nvim_archive"
}

install_miniconda() {
  log "Installing Miniconda ${MINICONDA_VERSION}..."
  local conda_arch="$ARCH"
  [ "$ARCH" = arm64 ] && conda_arch=aarch64
  local installer="Miniconda3-${MINICONDA_VERSION}-Linux-${conda_arch}.sh"
  download_and_verify \
    "https://repo.anaconda.com/miniconda/${installer}" \
    "$installer" "$(sha_for miniconda)"
  bash "$installer" -b -p "$HOME/.miniconda"
  rm "$installer"
}

install_uv() {
  log "Installing uv ${UV_VERSION}..."
  local target="${RUST_ARCH}-unknown-linux-gnu"
  local archive="uv-${target}.tar.gz"
  download_and_verify \
    "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/${archive}" \
    "$archive" "$(sha_for uv)"
  tar -xzf "$archive"
  install "uv-${target}/uv" "uv-${target}/uvx" -D -t "$HOME/.local/bin"
  rm -rf "$archive" "uv-${target}"
}

install_chrome() {
  log "Installing Google Chrome..."
  [ "$DEB_ARCH" = amd64 ] || { log "Chrome is unavailable for $ARCH; skipping."; return; }
  if [[ "$ID" == "debian" || "$ID" == "ubuntu" || "$ID" == "linuxmint" || "${ID_LIKE:-}" == *"debian"* || "${ID_LIKE:-}" == *"ubuntu"* ]]; then
    local chrome_deb="google-chrome-stable_current_amd64.deb"
    curl --fail --location --retry 3 --retry-all-errors --output "$chrome_deb" "https://dl.google.com/linux/direct/${chrome_deb}"
    sudo apt install -y "./${chrome_deb}"
    rm "$chrome_deb"
  elif [[ "$ID" == "arch" || "$ID" == "manjaro" || "${ID_LIKE:-}" == *"arch"* ]]; then
    log "Google Chrome is not in the official Arch repositories; use an AUR helper."
  else
    local chrome_rpm="google-chrome-stable_current_x86_64.rpm"
    curl --fail --location --retry 3 --retry-all-errors --output "$chrome_rpm" "https://dl.google.com/linux/direct/${chrome_rpm}"
    if [[ "$ID" == opensuse-* || "${ID_LIKE:-}" == *"suse"* ]]; then
      sudo zypper install -y "./${chrome_rpm}"
    else
      sudo dnf install -y "./${chrome_rpm}"
    fi
    rm "$chrome_rpm"
  fi
}

install_fzf() {
  log "Installing fzf ${FZF_VERSION}..."
  local version="${FZF_VERSION#v}"
  local archive="fzf-${version}-linux_${FZF_ARCH}.tar.gz"
  download_and_verify \
    "https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/${archive}" \
    "$archive" "$(sha_for fzf)"
  tar xf "$archive" -C "$HOME/.local/bin"
  rm "$archive"
}

install_lazygit() {
  log "Installing Lazygit ${LAZYGIT_VERSION}..."
  local version="${LAZYGIT_VERSION#v}"
  local archive="lazygit_${version}_linux_${ARCH}.tar.gz"
  download_and_verify \
    "https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/${archive}" \
    "$archive" "$(sha_for lazygit)"
  tar xf "$archive" lazygit
  install lazygit -D -t "$HOME/.local/bin"
  rm -f lazygit "$archive"
}

install_zoxide() {
  log "Installing Zoxide ${ZOXIDE_VERSION}..."
  local version="${ZOXIDE_VERSION#v}"
  local target="${RUST_ARCH}-unknown-linux-musl"
  local archive="zoxide-${version}-${target}.tar.gz"
  download_and_verify \
    "https://github.com/ajeetdsouza/zoxide/releases/download/${ZOXIDE_VERSION}/${archive}" \
    "$archive" "$(sha_for zoxide)"
  tar xf "$archive" zoxide
  install zoxide -D -t "$HOME/.local/bin"
  rm -f zoxide "$archive"
}

# =============================================================================
# Configuration Functions
# =============================================================================

setup_shell_environment() {
  log "Setting up shell environment..."

  # Install Prezto
  if [ ! -d "${ZDOTDIR:-$HOME}/.zprezto" ]; then
    clone_pinned https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto" "$PREZTO_COMMIT" true
  fi

  # Install conda completion
  if [ ! -d "${ZDOTDIR:-$HOME}/.zprezto/contrib/conda-zsh-completion" ]; then
    clone_pinned https://github.com/conda-incubator/conda-zsh-completion.git \
      "${ZDOTDIR:-$HOME}/.zprezto/contrib/conda-zsh-completion" "$CONDA_ZSH_COMPLETION_COMMIT"
  fi

  # Change default shell to zsh
  local zsh_path
  zsh_path="$(command -v zsh || true)"
  if [ -n "$zsh_path" ] && [ "$SHELL" != "$zsh_path" ]; then
    chsh -s "$zsh_path" || log "Could not change shell to zsh automatically; run 'chsh -s $zsh_path' manually"
  fi
}

setup_dotfiles() {
  log "Setting up dotfiles..."
  stow --no-folding -t "$HOME" conda fonts git nvim podman prettier tmux zsh
}

setup_tmux() {
  log "Setting up Tmux..."

  if [ ! -d ~/.tmux/plugins/tpm ]; then
    clone_pinned https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm "$TPM_COMMIT"
  fi
}

setup_fonts() {
  log "Setting up fonts..."

  # Load user fonts
  fc-cache -fv

  # Install the version-matched Nerd Font symbol configuration.
  local symbols_config="10-nerd-font-symbols.conf"
  download_and_verify \
    "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/${NERD_FONTS_VERSION}/${symbols_config}" \
    "$symbols_config" "$(sha_for nerd-fonts-config)"
  sudo install -m 0644 "$symbols_config" /usr/share/fontconfig/conf.avail/
  rm "$symbols_config"

  sudo ln -sf /usr/share/fontconfig/conf.avail/10-nerd-font-symbols.conf \
    /etc/fonts/conf.d/10-nerd-font-symbols.conf

  local nerd_fonts_zip="NerdFontsSymbolsOnly.zip"
  download_and_verify \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/${nerd_fonts_zip}" \
    "$nerd_fonts_zip" "$(sha_for nerd-fonts)"
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
  if [ "$CONFIGURE_WSL_DNS" = true ] && ! grep -q "\[network\]" /etc/wsl.conf; then
    echo -e "\n[network]\ngenerateResolvConf = false\n" | sudo tee -a /etc/wsl.conf
  fi

  # Replacing resolv.conf is disruptive, so it is explicitly opt-in.
  if [ "$CONFIGURE_WSL_DNS" = true ] && [ -L /etc/resolv.conf ]; then
    sudo unlink /etc/resolv.conf 2>/dev/null || true
    echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
    sudo chattr +i /etc/resolv.conf
  fi

  # Link Windows cmd.exe
  if [ ! -f "$HOME/.local/bin/cmd.exe" ]; then
    mkdir -p "$HOME/.local/bin"
    ln -s /mnt/c/WINDOWS/system32/cmd.exe "$HOME/.local/bin/cmd.exe"
  fi
}

setup_npm() {
  log "Configuring npm..."
  npm config set prefix ~/.local
}

# =============================================================================
# Main Installation Flow
# =============================================================================

main() {
  parse_args "$@"
  configure_architecture
  log "Starting development environment setup..."

  # shellcheck source=/dev/null
  if [ -f /etc/os-release ]; then . /etc/os-release; fi
  if [ "$DRY_RUN" = true ]; then print_dry_run; return; fi

  # Detect and install packages for the current distribution
  if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    case "$ID" in
    "debian")
      install_debian_packages
      ;;
    "linuxmint")
      install_debian_packages
      ;;
    "ubuntu")
      install_ubuntu_packages
      ;;
    "fedora")
      install_fedora_packages
      ;;
    "arch")
      install_arch_packages
      ;;
    "manjaro")
      install_arch_packages
      ;;
    "opensuse-tumbleweed" | "opensuse-leap" | "opensuse-microos")
      install_opensuse_packages
      ;;
    *)
      # Fallback: use ID_LIKE to detect the distribution family
      if [[ "${ID_LIKE:-}" == *"ubuntu"* || "$ID_LIKE" == *"debian"* ]]; then
        log "Detected Debian/Ubuntu-based distribution ($ID), installing compatible packages..."
        install_debian_packages
      elif [[ "${ID_LIKE:-}" == *"fedora"* || "$ID_LIKE" == *"rhel"* ]]; then
        log "Detected Fedora/RHEL-based distribution ($ID), installing compatible packages..."
        install_fedora_packages
      elif [[ "${ID_LIKE:-}" == *"arch"* ]]; then
        log "Detected Arch-based distribution ($ID), installing compatible packages..."
        install_arch_packages
      elif [[ "${ID_LIKE:-}" == *"opensuse"* || "$ID_LIKE" == *"suse"* ]]; then
        log "Detected openSUSE-based distribution ($ID), installing compatible packages..."
        install_opensuse_packages
      else
        error "Distribution $ID not supported. Supported: debian, ubuntu, fedora, arch, opensuse-tumbleweed, opensuse-leap and their derivatives"
      fi
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
  install_miniconda
  install_uv
  if [ "$INSTALL_CHROME" = true ]; then install_chrome; fi
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
  if [ "$INSTALL_DOCKER" = true ]; then setup_docker_completion; fi
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
