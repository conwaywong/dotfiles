# Steps

## Clone dotfiles repo and run init script

```bash
mkdir $HOME/dev; \
  cd $HOME/dev; \
  git clone https://github.com/conwaywong/dotfiles.git; \
  cd dotfiles && ./setup.sh
```

To skip installation support of NVIDIA, set the environment variable
`NVIDIA_SKIP`. For example,

```bash
NVIDIA_SKIP=true ./setup.sh
```

## Post install steps

Extend environment-specific settings by creating `$HOME/.zshenv_ext` and adding
variables to it. The file should automatically be loaded by $HOME/.zshenv.

## Create SSH Key

```bash
. /etc/os-release; ssh-keygen -t ed25519 -C "$USER@$(hostname)-$NAME-$VERSION_ID"
```
