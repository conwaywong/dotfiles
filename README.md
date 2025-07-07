# Create SSH Key

`ssh-keygen -t ed25519 -C "$USER@$(hostname)-Ubuntu-$(cat /etc/os-release | awk -F'=' '/VERSION_ID/ {
gsub(/"/, "", $2); print $2}')"`

Add public key to [https://github.com/settings/keys](https://github.com/settings/keys)

# Clone dotfiles repo

`mkdir $HOME/dev; cd $HOME/dev; git clone git@github.com:conwaywong/dotfiles.git`

# Run init script

`bash init.sh`

# Post install steps

* Open `vim`.  Run `:PlugUpdate`
