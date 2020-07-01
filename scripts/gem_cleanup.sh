## Gem clean up
# Vendored libgit2 shouldn't be needed once the gem is compiled
rm -rf gems/rugged-*/vendor

# *.o files shouldn't be needed once gems are compiled
find gems/**/ -name *.o -delete
find bundler/gems/**/ -name *.o -delete

# Remove tests that are shipped with gems
find gems/**/ -maxdepth 2 -name spec -type d -exec rm -rf {} +
find gems/**/ -maxdepth 2 -name test -type d -exec rm -rf {} +
find bundler/gems/**/ -maxdepth 2 -name spec -type d -exec rm -rf {} +
find bundler/gems/**/ -maxdepth 2 -name test -type d -exec rm -rf {} +

# Git directories are not needed, a new gem directory is created on update
find bundler/gems/**/ -maxdepth 2 -name .git -type d -exec rm -rf {} +

# Remove gem docs directories
find gems/**/ -maxdepth 2 -name docs -type d -exec rm -rf {} +
find bundler/gems/**/ -maxdepth 2 -name docs -type d -exec rm -rf {} +

# Remove node_modules
find gems/**/ -maxdepth 2 -name node_modules -type d -exec rm -rf {} +
find bundler/gems/**/ -maxdepth 2 -name node_modules -type d -exec rm -rf {} +

# Remove files with inappropriate license
rm -rf gems/pdf-writer-*/demo  # Creative Commons Attribution NonCommercial
