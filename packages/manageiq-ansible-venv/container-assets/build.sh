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

# Generate manifest
pip3 install pip-licenses
pip-licenses --from=mixed --format=csv --output-file=$VENV_ROOT/ansible_venv_manifest.csv
pip3 uninstall -y pip-licenses PTable

deactivate

# Build RPM
# Exclude symlinks from tarball, will be handled in rpm spec
echo "*** Building rpm"
mkdir -p $rpm_path
tar -C $VENV_ROOT --transform "s,^,$rpm_name-$VERSION/," --exclude='venv/bin/python' --exclude='venv/bin/python3' --exclude='venv/lib64' \
    -zcf $rpm_path/$rpm_name-$VERSION.tar.gz .

sed -i "s/ORG_NAME/$ORG_NAME/" $RPM_SPEC
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
