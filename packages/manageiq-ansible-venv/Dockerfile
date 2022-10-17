FROM registry.access.redhat.com/ubi8/ubi

# For productization
ENV ORG_NAME=manageiq \
    PRODUCT_NAME=manageiq \
    PRODUCT_SUMMARY="ManageIQ Management Engine"

ENV RPM_SPEC=manageiq-ansible-venv.spec \
    VENV_ROOT=/var/lib/manageiq \
    VERSION=1.0.0

# CentOS repo needed for rpm-build
RUN ARCH=$(uname -m) && \
    if [ ${ARCH} != "s390x" ] ; then dnf -y remove *subscription-manager*; fi && \
    dnf config-manager --setopt=tsflags=nodocs --save && \
    dnf -y install \
      http://mirror.centos.org/centos/8-stream/BaseOS/${ARCH}/os/Packages/centos-stream-repos-8-2.el8.noarch.rpm \
      http://mirror.centos.org/centos/8-stream/BaseOS/${ARCH}/os/Packages/centos-gpg-keys-8-2.el8.noarch.rpm && \
    dnf -y install \
      gcc \
      krb5-devel \
      libcurl-devel \
      libffi-devel \
      libxml2-devel \
      libxslt-devel \
      make \
      openssl-devel \
      python38-devel \
      python38-pip \
      rpm-build && \
    dnf clean all && \
    rm -rf /var/cache/dnf

COPY $RPM_SPEC container-assets/build.sh /
COPY requirements.txt $VENV_ROOT/

CMD ["/build.sh"]
