# ManageIQ Ansible Virtualenv RPM Build

Builds RPM for ManageIQ Ansible Virtualenv in a container image

## Usage

- To build RPM locally in container:

  `docker run -ti manageiq/ansible_venv_rpm_build`

  Bind mount `/root/rpms` to obtain the artifacts

- To build RPM in Copr:

  `docker run -ti -v <path to copr config>:/root/.config/copr -e COPR_CHROOT=<chroot> -e COPR_PROJECT=<project> manageiq/ansible_venv_rpm_build`

- To run container without kicking off build:

  `docker run -ti manageiq/ansible_venv_rpm_build bash`

   Run `./build.sh` to start the build.

### Productization

The rpm prefix, rpm summary info, and org name can be changed during build. To productize, run with:

`-e PRODUCT_NAME=<name> -e PRODUCT_SUMMARY=<summary> -e ORG_NAME=<org name>`

 - PRODUCT_NAME = used for rpm prefix: `<name>-ansible-venv`, should match `product_name` in config/options.yml for manageiq RPMs, default: manageiq
 - PRODUCT_SUMMARY = used for rpm summary/description, default: ManageIQ Management Engine
 - ORG_NAME = used for manifest path: `/opt/<org name>/manifest`, should match `rpm.org_name` in config/options.yml for manageiq RPMs, default: manageiq
