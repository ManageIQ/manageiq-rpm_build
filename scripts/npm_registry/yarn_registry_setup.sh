#!/bin/bash

NPM_REGISTRY_OVERRIDE="$1"
yarn config set npmRegistryServer ${NPM_REGISTRY_OVERRIDE}

# Replace registry in existing yarn.lock
ui_plugin_repos=`rake update:print_engines | grep path: | cut -d: -f2`
for repo in ${ui_plugin_repos} ../manageiq-ui-service
do
  lock_file="${repo}/yarn.lock"
  if [ -f "${lock_file}" ]; then
    sed -i "s#https\?://registry.\(npmjs\|yarnpkg\).\(org\|com\)#${NPM_REGISTRY_OVERRIDE}#g" ${lock_file}
  fi
done
