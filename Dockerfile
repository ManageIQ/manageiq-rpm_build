FROM registry.access.redhat.com/ubi9/ubi

ENV TERM=xterm \
    APPLIANCE=true \
    RAILS_USE_MEMORY_STORE=true

# Force the sticky bit on /tmp - https://bugzilla.redhat.com/show_bug.cgi?id=2138434
RUN chmod +t /tmp

RUN ARCH=$(uname -m) && \
    if [ ${ARCH} != "s390x" ] ; then dnf -y remove *subscription-manager*; fi && \
    dnf -y update && \
    dnf -y --setopt=protected_packages= remove redhat-release && \
    dnf -y install --releasever 9 \
      http://mirror.stream.centos.org/9-stream/BaseOS/${ARCH}/os/Packages/centos-stream-release-9.0-24.el9.noarch.rpm \
      http://mirror.stream.centos.org/9-stream/BaseOS/${ARCH}/os/Packages/centos-stream-repos-9.0-24.el9.noarch.rpm \
      http://mirror.stream.centos.org/9-stream/BaseOS/${ARCH}/os/Packages/centos-gpg-keys-9.0-24.el9.noarch.rpm && \
    dnf -y install \
      https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
      https://rpm.manageiq.org/release/18-radjabov/el9/noarch/manageiq-release-18.0-1.el9.noarch.rpm && \
    dnf -y module enable ruby:3.1 && \
    dnf -y module enable nodejs:18 && \
    dnf -y group install "development tools" && \
    dnf config-manager --setopt=tsflags=nodocs --save && \
    dnf -y install \
      cmake \
      copr-cli \
      createrepo \
      glibc-langpack-en \
      libcurl-devel \
      libpq-devel \
      librdkafka \
      libssh2-devel \
      libxml2-devel \
      libxslt-devel \
      nodejs \
      openssl-devel \
      platform-python-devel \
      postgresql-server \
      qpid-proton-c-devel \
      ruby-default-gems-3.1.2 \
      ruby-devel-3.1.2 \
      wget \
      # For seeding ansible runner with ansible-galaxy, and for ansible-venv
      ansible \
      # For ansible-venv
      cargo \
      gcc \
      krb5-devel \
      libcurl-devel \
      libffi-devel \
      libxml2-devel \
      libxslt-devel \
      make \
      openssl-devel \
      python3-devel \
      python3-pip \
      python3-virtualenv \
      rpm-build && \
    dnf -y update libarchive && \
    dnf clean all && \
    rm -rf /var/cache/dnf

RUN npm install yarn -g

RUN echo "gem: --no-ri --no-rdoc --no-document" > /root/.gemrc

COPY . /build_scripts

RUN curl -o /usr/lib/rpm/brp-strip https://raw.githubusercontent.com/rpm-software-management/rpm/rpm-4.19.1-release/scripts/brp-strip && \
  chmod +x /usr/lib/rpm/brp-strip && \
  cd /usr/lib/rpm/ && \
  patch -p2 < /build_scripts/container-assets/Add-js-rb-filtering-on-top-of-4.19.1.patch

RUN gem install bundler

ENTRYPOINT ["/build_scripts/container-assets/user-entrypoint.sh"]
