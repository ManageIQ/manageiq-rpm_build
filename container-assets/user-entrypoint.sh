#!/bin/bash

export GEM_HOME=$(ruby -e 'puts Gem.user_dir')
export PATH=$GEM_HOME/bin:$HOME/bin:$PATH

if [[ $# -eq 0 ]]; then
  cmd="/bin/bash"
elif [[ $1 == "build" ]]; then
  shift
  cmd="bin/build.rb $@"
else
  echo "Run with no argument to setup build environment, or"
  echo "Run with 'build <build.rb options>' to start bin/build.rb (e.g. build --git-ref jansa)"
  exit
fi

cd /build_scripts
bundle
$cmd
