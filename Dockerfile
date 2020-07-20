FROM registry.access.redhat.com/ubi8/ubi:8.2

ARG ARCH=x86_64

ENV TERM=xterm \
    APPLIANCE=true \
    RAILS_USE_MEMORY_STORE=true

RUN curl -L https://releases.ansible.com/ansible-runner/ansible-runner.el8.repo > /etc/yum.repos.d/ansible-runner.repo

RUN dnf -y --disableplugin=subscription-manager install http://mirror.centos.org/centos/8.2.2004/BaseOS/${ARCH}/os/Packages/centos-repos-8.2-2.2004.0.1.el8.${ARCH}.rpm \
                                                        http://mirror.centos.org/centos/8.2.2004/BaseOS/${ARCH}/os/Packages/centos-gpg-keys-8.2-2.2004.0.1.el8.noarch.rpm \
                                                        https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
                                                        https://rpm.manageiq.org/release/10-jansa/el8/noarch/manageiq-release-10.0-1.el8.noarch.rpm && \
    dnf -y --disableplugin=subscription-manager module enable ruby:2.6 && \
    dnf -y --disableplugin=subscription-manager module enable nodejs:12 && \
    dnf -y --disableplugin=subscription-manager groupinstall "development tools" && \
    dnf config-manager --setopt=epel.exclude=*qpid-proton* --save && \
    dnf config-manager --set-enabled PowerTools && \
    dnf -y --disableplugin=subscription-manager --setopt=tsflags=nodocs install \
      ansible \
      cmake \
      copr-cli \
      createrepo \
      glibc-langpack-en \
      libcurl-devel \
      libpq-devel \
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
      wget

RUN npm install yarn -g

RUN echo "gem: --no-ri --no-rdoc --no-document" > /root/.gemrc

RUN if [ ${ARCH} = "ppc64le" ] ; then dnf -y install python2 ; fi

COPY . /build_scripts

ENTRYPOINT ["/build_scripts/container-assets/user-entrypoint.sh"]
