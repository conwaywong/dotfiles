# Dotfiles

Development environment setup for Linux and WSL2. Installs packages, tools,
and shell configuration with a single script.

## Supported Distributions

| Distribution | Package Manager |
|---|---|
| Ubuntu | apt |
| Debian | apt |
| Linux Mint | apt |
| Fedora | dnf |
| Arch Linux | pacman |
| Manjaro | pacman |
| openSUSE Tumbleweed / Leap / MicroOS | zypper |
| Derivatives (Pop!_OS, Kali, EndeavourOS, etc.) | detected via `ID_LIKE` |

## Quick Start

```bash
mkdir -p $HOME/dev && \
  cd $HOME/dev && \
  git clone https://github.com/conwaywong/dotfiles.git && \
  cd dotfiles && ./setup.sh
```

### Options

Run `./setup.sh --help` for all options. Common safe modes:

```bash
# Preview choices without changing the system
./setup.sh --dry-run

# Avoid broad or optional system changes
./setup.sh --no-system-upgrade --no-docker --no-chrome --no-nvidia
```

Package removal and fixed WSL DNS are opt-in via `--remove-unwanted` and
`--configure-wsl-dns`.

## What Gets Installed

### System Packages

Core utilities installed across all distros:

| Tool | Description |
|---|---|
| bat | `cat` with syntax highlighting |
| btop | Interactive process viewer (`top` replacement) |
| fd | Fast `find` alternative |
| fzf | Fuzzy finder with shell integration |
| jq | JSON processor |
| meld | Visual diff and merge tool |
| ripgrep | Fast `grep` alternative |
| silversearcher-ag | `ag` code search tool |
| stow | Symlink farm manager (used to deploy dotfiles) |
| tidy | HTML/XML formatter |
| tldr | Simplified man pages |
| tmux | Terminal multiplexer |
| zoxide | Smart `cd` replacement |
| zsh | Z shell |

### Applications

Downloaded and installed from upstream releases:

| Application | Version | Notes |
|---|---|---|
| Neovim | v0.12.5 | Installed to `/opt/nvim/` |
| Miniconda | py313_26.7.1-1 | Installed to `~/.miniconda/` |
| uv | 0.12.8 | Python package manager |
| fzf | v0.74.3 | Installed to `~/.local/bin/` |
| Lazygit | v0.64.1 | Installed to `~/.local/bin/` |
| Google Chrome | stable | Skipped on Arch (install via AUR: `yay -S google-chrome`) |

### Docker

Docker CE is installed on all distros including `docker-buildx-plugin` and
`docker-compose-plugin`. The current user is added to the `docker` group.

### NVIDIA / CUDA (WSL2 only)

Detected automatically by the presence of
`/mnt/c/Windows/System32/nvidia-smi.exe`. Installs:

- `cuda-toolkit-13` (latest CUDA 13.x available for the distribution)
- `nvtop`
- NVIDIA Container Toolkit (configured for Docker)

Use `--no-nvidia` (or `NVIDIA_SKIP=true`) to skip.

## Shell Configuration

**Shell:** Zsh with [Prezto](https://github.com/sorin-ionescu/prezto)

**Theme:** [Powerlevel10k](https://github.com/romkatv/powerlevel10k)

**Prezto modules loaded:** `environment`, `history`, `directory`,
`syntax-highlighting`, `ssh`, `utility`, `completion`,
`history-substring-search`, `prompt`, `conda-zsh-completion`, `tmux`

**Integrations configured in `~/.zshrc`:**

- **fzf** — key bindings and fuzzy tab completion
- **Conda** — shell hook for environment activation
- **uv** — shell completion for `uv` and `uvx`
- **Zoxide** — replaces `cd` with smart directory jumping (`z`)
- **Docker** — tab completion via `~/.docker/completions/`
- **Tmux** — auto-starts a session on terminal launch

**Useful aliases (`.zsh_aliases`):**

| Alias | Command |
|---|---|
| `update` | Distro-appropriate full system upgrade |
| `cat` | `batcat` (if installed) |
| `top` | `btop` (if installed) |
| `fd` | `fdfind` (if installed) |
| `cd` | `z` (zoxide, if installed) |
| `lg` | `lazygit` (if installed) |
| `vi` / `vim` | `nvim` (if installed) |
| `ll` | `ls -alh` |

### PATH

`~/.local/bin`, `/opt/nvim/bin`, and Java/Maven paths
(`/opt/java/jdk-current/bin`, `/opt/maven/current/bin`) are added via
`~/.zshenv`.

## Tmux Configuration

- **Prefix:** `Ctrl+S`
- **Theme:** [Catppuccin](https://github.com/catppuccin/tmux) v2.3.0
- **Plugins:** `vim-tmux-navigator`, `tpm`
- **Status bar:** top-positioned, shows current application name
- **Mouse:** enabled
- **Windows:** numbered from 1, auto-renumbered on close
- **Reload config:** `prefix + r`

## Git Configuration

- **Diff/merge tool:** Meld (3-way merge)
- **Credentials:** cached in memory for 12 hours (not written to disk)
- **Auto-prune:** remote branches pruned on fetch

Aliases:

| Alias | Expands to |
|---|---|
| `git st` | `git status -bs` |
| `git co` | `git checkout` |
| `git d` | `git diff` |
| `git dt` | `git difftool` |
| `git ls` | Decorated one-line log |
| `git ll` | Decorated log with file stats |

## WSL2-Specific Setup

When running under WSL2, the script additionally:

- Sets `appendWindowsPath = false` in `/etc/wsl.conf` to prevent Windows
  `PATH` pollution
- Optionally disables auto-generated `/etc/resolv.conf` and sets DNS to `8.8.8.8`
  when `--configure-wsl-dns` is supplied
- Links `cmd.exe` to `~/.local/bin/cmd.exe`
- Sets `BROWSER` to `/mnt/c/Windows/explorer.exe` for opening URLs in the Windows default browser
- Sets `XDG_RUNTIME_DIR` to `/mnt/wslg/runtime-dir`

## Post-Install Steps

### Extend environment variables

Create `~/.zshenv_ext` to add machine-specific settings (automatically sourced
by `~/.zshenv`):

```bash
# Example ~/.zshenv_ext
export MY_TOKEN=...
export CUSTOM_PATH=...
```

### Create an SSH key

```bash
. /etc/os-release; ssh-keygen -t ed25519 -C "$USER@$(hostname)-$NAME-$VERSION_ID"
```

## Repository Structure

```
dotfiles/
├── bash/        Bash configuration
├── conda/       Conda configuration (.condarc)
├── continue/    Continue IDE extension config
├── fonts/       Nerd Font symbols config (deployed via stow)
├── git/         Git configuration (.gitconfig)
├── nvim/        Neovim configuration (LazyVim-based, Lua)
├── podman/      Podman container configuration
├── prettier/    Prettier code formatter config
├── screen/      GNU Screen configuration
├── tmux/        Tmux configuration (.tmux.conf)
├── vim/         Vim configuration (.vimrc)
├── zsh/         Zsh configuration (.zshrc, .zshenv, .zpreztorc, .zsh_aliases, .p10k.zsh)
├── scripts/     Release/checksum validation utilities
└── setup.sh     Main install and configuration script
```


## Development and Validation

GitHub Actions runs Bash, Zsh, tmux, ShellCheck, dry-run, and pinned-release
validation. Run the portable checks locally with:

```bash
bash -n setup.sh
git diff --check
./setup.sh --dry-run
python3 scripts/check-releases.py
```

Downloaded release archives are pinned and SHA-256 verified. Renovate monitors
pinned GitHub releases; Dependabot monitors GitHub Actions.
