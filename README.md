# Create SSH Key

`ssh-keygen -t ed25519 -C "cwong@<host>"`

Add public key to [https://github.com/settings/keys](https://github.com/settings/keys)

# Clone dotfiles repo

`mkdir $HOME/dev; cd $HOME/dev; git clone git@github.com:conwaywong/dotfiles.git`

# Run init script

`bash init.sh`

# Post install steps

* Open `vim`.  Run `:PlugUpdate`
