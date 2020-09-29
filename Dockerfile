FROM registry.access.redhat.com/ubi8/ubi:8.2

ARG ARCH=x86_64

ENV TERM=xterm \
    APPLIANCE=true \
    RAILS_USE_MEMORY_STORE=true

RUN curl -L https://releases.ansible.com/ansible-runner/ansible-runner.el8.repo > /etc/yum.repos.d/ansible-runner.repo

#Install libssh2-devel for s390x
RUN if [ ${ARCH} = "s390x" ] ; then dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf -y install https://kojipkgs.fedoraproject.org/packages/libssh2/1.9.0/5.epel8.playground/s390x/libssh2-1.9.0-5.epel8.playground.s390x.rpm && \
    dnf -y install https://kojipkgs.fedoraproject.org/packages/libssh2/1.9.0/5.epel8.playground/s390x/libssh2-devel-1.9.0-5.epel8.playground.s390x.rpm ; else \
RUN dnf -y --disableplugin=subscription-manager install http://mirror.centos.org/centos/8.2.2004/BaseOS/${ARCH}/os/Packages/centos-repos-8.2-2.2004.0.1.el8.${ARCH}.rpm \
                                                        http://mirror.centos.org/centos/8.2.2004/BaseOS/${ARCH}/os/Packages/centos-gpg-keys-8.2-2.2004.0.1.el8.noarch.rpm ; fi
  RUN dnf -y --disableplugin=subscription-manager install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
 https://rpm.manageiq.org/release/11-kasparov/el8/noarch/manageiq-release-11.0-1.el8.noarch.rpm && \
    dnf -y --disableplugin=subscription-manager module enable ruby:2.6 && \
    dnf -y --disableplugin=subscription-manager module enable nodejs:12 && \
    dnf -y --disableplugin=subscription-manager groupinstall "development tools" && \
    dnf config-manager --setopt=epel.exclude=*qpid-proton* --save && \
    if [ ${ARCH} != "s390x" ] ; then dnf config-manager --set-enabled PowerTools ; fi && \
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
      libffi-devel \
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

RUN if [ ${ARCH} = "s390x" ]  || [ ${ARCH} = "ppc64le"] ; then dnf -y install python2 ; fi

RUN npm install yarn -g

RUN if [ ${ARCH} = "s390x" ] ; then npm config --global set python /usr/bin/python2.7 ; fi

RUN echo "gem: --no-ri --no-rdoc --no-document" > /root/.gemrc

COPY . /build_scripts

ENTRYPOINT ["/build_scripts/container-assets/user-entrypoint.sh"]


