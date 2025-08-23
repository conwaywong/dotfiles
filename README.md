# Steps

## Clone dotfiles repo and run init script

```bash
mkdir $HOME/dev; \
  cd $HOME/dev; \
  git clone https://github.com/conwaywong/dotfiles.git; \
  cd dotfiles && ./setup.sh
```

## Post install steps

Extend environment-specific settings by creating a `$HOME/.zshenv_ext` and
adding to it.

## Create SSH Key

```bash
. /etc/os-release; ssh-keygen -t ed25519 -C "$USER@$(hostname)-$NAME-$VERSION_ID"
```
