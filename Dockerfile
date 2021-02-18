FROM registry.access.redhat.com/ubi8/ubi:8.3

ARG ARCH=x86_64

ENV TERM=xterm \
    APPLIANCE=true \
    RAILS_USE_MEMORY_STORE=true

RUN curl -L https://releases.ansible.com/ansible-runner/ansible-runner.el8.repo > /etc/yum.repos.d/ansible-runner.repo

RUN sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/subscription-manager.conf

RUN if [ ${ARCH} != "s390x" ] ; then dnf -y install http://mirror.centos.org/centos/8.3.2011/BaseOS/${ARCH}/os/Packages/centos-linux-repos-8-2.el8.noarch.rpm \
                                                    http://mirror.centos.org/centos/8.3.2011/BaseOS/${ARCH}/os/Packages/centos-gpg-keys-8-2.el8.noarch.rpm; fi && \
    dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
                   https://rpm.manageiq.org/release/12-lasker/el8/noarch/manageiq-release-12.0-1.el8.noarch.rpm && \
    dnf -y module enable ruby:2.6 && \
    dnf -y module enable nodejs:12 && \
    dnf -y module disable virt:rhel && \
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
      libsodium-devel \
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
      rubygem-bundler \
      sqlite-devel \
      wget && \
    dnf clean all

RUN if [ ${ARCH} = "s390x" ] || [ ${ARCH} = "ppc64le" ] ; then dnf -y install python2 ; fi

RUN npm install yarn -g

RUN echo "gem: --no-ri --no-rdoc --no-document" > /root/.gemrc

COPY . /build_scripts

ENTRYPOINT ["/build_scripts/container-assets/user-entrypoint.sh"]
