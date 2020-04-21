#!/bin/bash

export GEM_HOME=$(ruby -e 'puts Gem.user_dir')
export PATH=$GEM_HOME/bin:$HOME/bin:$PATH

cd /build_scripts
bundle

/bin/bash
