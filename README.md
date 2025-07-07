# Create SSH Key

```bash
ssh-keygen -t ed25519 -C "$USER@$(hostname)-Ubuntu-$(cat /etc/os-release | awk -F'=' '/VERSION_ID/ {
gsub(/"/, "", $2); print $2}')"
cat ~/.ssh/id_ed25519.pub
```

Add public key to [https://github.com/settings/keys](https://github.com/settings/keys)

# Clone dotfiles repo

`mkdir $HOME/dev; cd $HOME/dev; git clone https://github.com/conwaywong/dotfiles.git`

# Run init script

`init.sh`

# Post install steps

* Open `vim`.  Run `:PlugUpdate`
