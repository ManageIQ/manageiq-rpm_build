#!/bin/bash

set -e

venv_path=$VENV_ROOT/venv
rpm_name=$PRODUCT_NAME-ansible-venv
rpm_path=/root/rpms

# Setup venv
echo "*** Setting up venv"
python3 -m venv $venv_path
source $venv_path/bin/activate
pip3 install --no-compile -r $VENV_ROOT/requirements.txt
deactivate

# Remove lib64 directory which is a symlink to lib, symlink will be created during rpm install
rm -f $venv_path/lib64

# Build RPM
echo "*** Building rpm"
mkdir -p $rpm_path
tar -C $VENV_ROOT --transform "s,^,$rpm_name-$VERSION/," -zcf $rpm_path/$rpm_name-$VERSION.tar.gz .

sed -i "s/PRODUCT_NAME/$rpm_name/" $RPM_SPEC
sed -i "s/PRODUCT_SUMMARY/$PRODUCT_SUMMARY/" $RPM_SPEC
sed -i "s/VERSION/$VERSION/" $RPM_SPEC
sed -i "s#VENV_ROOT#$VENV_ROOT#" $RPM_SPEC

if [ -f "/root/.config/copr" ]; then
  rpmbuild -bs --define "_sourcedir $rpm_path" --define "_srcrpmdir $rpm_path" /$RPM_SPEC
  copr-cli build -r $COPR_CHROOT $COPR_PROJECT $rpm_path/*.src.rpm
else
  rpmbuild -bb --define "_sourcedir $rpm_path" --define "_rpmdir $rpm_path" /$RPM_SPEC
fi
