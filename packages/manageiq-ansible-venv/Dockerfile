FROM registry.access.redhat.com/ubi8/ubi:8.2

ARG ARCH=x86_64

ENV NAME=manageiq-ansible-venv \
    VERSION=1.0.0 \
    VENV_ROOT=/var/lib/manageiq \
    RPM_SPEC=manageiq-ansible-venv.spec

# CentOS repos: rpm-build and copr-cli dependencies
# EPEL: copr-cli
RUN dnf -y --disableplugin=subscription-manager install \
      http://mirror.centos.org/centos/8.2.2004/BaseOS/${ARCH}/os/Packages/centos-repos-8.2-2.2004.0.1.el8.${ARCH}.rpm \
      http://mirror.centos.org/centos/8.2.2004/BaseOS/${ARCH}/os/Packages/centos-gpg-keys-8.2-2.2004.0.1.el8.noarch.rpm \
      https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf -y --disableplugin=subscription-manager --setopt=tsflags=nodocs install \
      copr-cli \
      gcc \
      libcurl-devel \
      libxml2-devel \
      openssl-devel \
      python3-devel \
      python3-virtualenv \
      rpm-build

COPY $RPM_SPEC container-assets/build.sh /
COPY requirements.txt $VENV_ROOT/

CMD ["/build.sh"]
