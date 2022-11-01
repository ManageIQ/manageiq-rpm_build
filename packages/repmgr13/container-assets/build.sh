#!/bin/bash

set -ev

rpm_path="/root/BUILD/rpms"
root="/root"

# Build RPM
echo "*** Building rpm $RPM_SPEC"
mkdir -p $rpm_path
cd $root

rpmbuild -v -bb \
  --undefine=_disable_source_fetch \
  --define "_sourcedir ${root}" \
  --define "_srcrpmdir ${root}" \
  --define "_rpmdir $rpm_path" \
  $RPM_SPEC
