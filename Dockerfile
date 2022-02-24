FROM registry.access.redhat.com/ubi8/ubi

ENV TERM=xterm \
    APPLIANCE=true \
    RAILS_USE_MEMORY_STORE=true

RUN ARCH=$(uname -m) && \
    if [ ${ARCH} != "s390x" ] ; then dnf -y remove *subscription-manager*; fi && \
    dnf -y update && \
    curl -L https://releases.ansible.com/ansible-runner/ansible-runner.el8.repo > /etc/yum.repos.d/ansible-runner.repo && \
    if [ ${ARCH} != "s390x" ] ; then dnf -y install \
      http://mirror.centos.org/centos/8-stream/BaseOS/${ARCH}/os/Packages/centos-stream-repos-8-2.el8.noarch.rpm \
      http://mirror.centos.org/centos/8-stream/BaseOS/${ARCH}/os/Packages/centos-gpg-keys-8-2.el8.noarch.rpm ; fi && \
    dnf -y install \
      https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
      https://rpm.manageiq.org/release/14-najdorf/el8/noarch/manageiq-release-14.0-1.el8.noarch.rpm && \
    dnf -y module enable ruby:2.7 && \
    dnf -y module enable nodejs:14 && \
    dnf -y module disable virt:rhel && \
    if [ ${ARCH} != "s390x" ] ; then dnf config-manager --setopt=ubi-8-*.exclude=rpm* --save; fi && \
    dnf -y group install "development tools" && \
    dnf config-manager --setopt=epel.exclude=*qpid-proton* --setopt=tsflags=nodocs --save && \
    dnf -y install \
      ansible \
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
      wget && \
    dnf -y update libarchive && \
    if [ ${ARCH} = "s390x" ] || [ ${ARCH} = "ppc64le" ] ; then dnf -y install python2 ; fi && \
    dnf clean all && \
    rm -rf /var/cache/dnf

RUN npm install yarn -g

RUN echo "gem: --no-ri --no-rdoc --no-document" > /root/.gemrc

COPY . /build_scripts

RUN gem install bundler

ENTRYPOINT ["/build_scripts/container-assets/user-entrypoint.sh"]
