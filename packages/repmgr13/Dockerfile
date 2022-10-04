FROM registry.access.redhat.com/ubi8/ubi

ENV TERM=xterm \
    RPM_SPEC=repmgr.spec

RUN ARCH=$(uname -m) && \
    # TODO figure out s390x
    dnf -y remove *subscription-manager* && \
    dnf -y update && \
    dnf -y install \
      http://mirror.centos.org/centos/8-stream/BaseOS/${ARCH}/os/Packages/centos-stream-repos-8-2.el8.noarch.rpm \
      http://mirror.centos.org/centos/8-stream/BaseOS/${ARCH}/os/Packages/centos-gpg-keys-8-2.el8.noarch.rpm \
      https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf -y module enable postgresql:13 && \
    dnf -y group install "development tools" && \
    dnf -y install \
      ccache \
      clang-devel \
      flex \
      libpq \
      libpq-devel \
      libxslt-devel \
      llvm-toolset \
      openssl-devel \
      pam-devel \
      postgresql \
      postgresql-devel \
      postgresql-static \
      readline-devel \
      wget && \
    dnf clean all && \
    rm -rf /var/cache/dnf

COPY . /root

CMD ["/root/container-assets/build.sh"]
