# Steps

## Clone dotfiles repo and run init script

```bash
mkdir $HOME/dev; \
  cd $HOME/dev; \
  git clone https://github.com/conwaywong/dotfiles.git; \
  cd dotfiles && ./setup.sh
```

## Post install steps

Extend environment-specific settings by creating a file `$HOME/.zshenv_ext` and
adding to it.

## Create SSH Key

```bash
ssh-keygen -t ed25519 -C "$USER@$(hostname)-Ubuntu-$(cat /etc/os-release | \
    awk -F'=' '/VERSION_ID/ {gsub(/"/, "", $2); print $2}')"
```
