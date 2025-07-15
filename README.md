# Steps

## Clone dotfiles repo and run init script

```bash
mkdir $HOME/dev; \
  cd $HOME/dev; \ 
  git clone https://github.com/conwaywong/dotfiles.git; \ 
  cd dotfiles && ./init.sh
```

## Post install steps

* Install TPM plugins by running `Ctrl-s Shift-i`

## Create SSH Key

```bash
ssh-keygen -t ed25519 -C "$USER@$(hostname)-Ubuntu-$(cat /etc/os-release | \
    awk -F'=' '/VERSION_ID/ {gsub(/"/, "", $2); print $2}')"
```
