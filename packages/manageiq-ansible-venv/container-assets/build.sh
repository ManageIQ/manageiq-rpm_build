#!/bin/bash

set -e

venv_path=$VENV_ROOT/venv
rpm_name=$PRODUCT_NAME-ansible-venv
rpm_path=/root/rpms

echo "*** Installing python system packages"
pip3.8 install virtualenv psutil==5.6.6

echo "*** Setting up venv"
mkdir -p $venv_path
virtualenv --system-site-packages $venv_path
source $venv_path/bin/activate

echo "*** Installing packages"
pip3.8 install --no-compile -r $VENV_ROOT/requirements.txt

echo "*** Generating manifest"
pip3.8 install pip-licenses
pip-licenses --from=mixed --format=csv --output-file=$VENV_ROOT/ansible_venv_manifest.csv
pip3.8 uninstall -y pip-licenses PTable

deactivate

echo "*** Cleanup venv"
rm -rf $venv_path/share/doc/*

echo "*** Building tarball"
# Exclude symlinks from tarball, will be handled in rpm spec
mkdir -p $rpm_path
tar -C $VENV_ROOT --transform "s,^,$rpm_name-$VERSION/," \
  --exclude='venv/bin/python' \
  --exclude='venv/bin/python3' \
  --exclude='venv/bin/python3.8' \
  --exclude='venv/lib64' \
  -zcf $rpm_path/$rpm_name-$VERSION.tar.gz .

echo "*** Building RPM"
sed -i "s/ORG_NAME/$ORG_NAME/" $RPM_SPEC
sed -i "s/PRODUCT_NAME/$rpm_name/" $RPM_SPEC
sed -i "s/PRODUCT_SUMMARY/$PRODUCT_SUMMARY/" $RPM_SPEC
sed -i "s/VERSION/$VERSION/" $RPM_SPEC
sed -i "s#VENV_ROOT#$VENV_ROOT#" $RPM_SPEC

rpmbuild -bb --define "_sourcedir $rpm_path" --define "_rpmdir $rpm_path" /$RPM_SPEC
