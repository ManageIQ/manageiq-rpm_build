FROM registry.access.redhat.com/ubi9/ubi

# For productization
ENV ORG_NAME=manageiq \
    PRODUCT_NAME=manageiq \
    PRODUCT_SUMMARY="ManageIQ Management Engine"

ENV RPM_SPEC=manageiq-ansible-venv.spec \
    VENV_ROOT=/var/lib/manageiq \
    VERSION=1.0.0

RUN ARCH=$(uname -m ) && \
    dnf config-manager --setopt=tsflags=nodocs --save && \
    dnf -y --setopt=protected_packages= remove redhat-release && \
    dnf -y remove *subscription-manager* && \
    dnf -y install \
      http://mirror.stream.centos.org/9-stream/BaseOS/${ARCH}/os/Packages/centos-stream-release-9.0-12.el9.noarch.rpm \
      http://mirror.stream.centos.org/9-stream/BaseOS/${ARCH}/os/Packages/centos-stream-repos-9.0-12.el9.noarch.rpm \
      http://mirror.stream.centos.org/9-stream/BaseOS/${ARCH}/os/Packages/centos-gpg-keys-9.0-12.el9.noarch.rpm && \
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
