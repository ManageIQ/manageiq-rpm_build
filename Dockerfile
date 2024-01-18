FROM registry.access.redhat.com/ubi8/ubi

ENV TERM=xterm \
    APPLIANCE=true \
    RAILS_USE_MEMORY_STORE=true

# Force the sticky bit on /tmp - https://bugzilla.redhat.com/show_bug.cgi?id=2138434
RUN chmod +t /tmp

RUN ARCH=$(uname -m) && \
    if [ ${ARCH} != "s390x" ] ; then dnf -y remove *subscription-manager*; fi && \
    dnf -y update && \
    if [ ${ARCH} != "s390x" ] ; then dnf -y install \
      http://mirror.centos.org/centos/8-stream/BaseOS/${ARCH}/os/Packages/centos-stream-repos-8-2.el8.noarch.rpm \
      http://mirror.centos.org/centos/8-stream/BaseOS/${ARCH}/os/Packages/centos-gpg-keys-8-2.el8.noarch.rpm ; fi && \
    dnf -y install \
      https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
      https://rpm.manageiq.org/release/17-quinteros/el8/noarch/manageiq-release-17.0-1.el8.noarch.rpm && \
    dnf -y module enable ruby:3.0 && \
    dnf -y module enable nodejs:18 && \
    dnf -y module disable virt:rhel && \
    if [ ${ARCH} != "s390x" ] ; then dnf config-manager --setopt=ubi-8-*.exclude=rpm* --save; fi && \
    dnf -y group install "development tools" && \
    dnf config-manager --setopt=epel.exclude=*qpid-proton* --setopt=tsflags=nodocs --save && \
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
      postgresql-server-devel \
      qpid-proton-c-devel \
      ruby-devel \
      wget \
      # For seeding ansible runner with ansible-galaxy, and for ansible-venv
      ansible-5.4.0-3.el8 \
      # For ansible-venv
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
