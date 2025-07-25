export JAVA_HOME=/opt/java/jdk-current

export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
export PATH="$HOME/.local/bin:$JAVA_HOME/bin:/opt/maven/current/bin:$PATH"

# See https://github.com/sbt/sbt/issues/8154#issuecomment-3012557515
if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
  export XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir
  export BROWSER=wslview
fi

# Add additional environment vars
if [ -f $HOME/.zshenv_ext ]; then
  source $HOME/.zshenv_ext
fi
