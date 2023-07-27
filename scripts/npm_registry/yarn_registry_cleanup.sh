#!/bin/bash

NPM_REGISTRY_OVERRIDE="$1"

if [[ $(uname -m) == "s390x" ]]; then
  # For yarn v1
  yarn config delete registry
else
  yarn config delete npmRegistryServer
fi

# Replace registry in yarn.lock
default_yarn_registry=`yarn config get npmRegistryServer`
ui_plugin_repos=`rake update:print_engines | grep path: | cut -d: -f2`
for repo in ${ui_plugin_repos}
do
  sed -i "s#${NPM_REGISTRY_OVERRIDE}#${default_yarn_registry}#g" ${repo}/yarn.lock
done
