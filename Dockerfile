FROM registry.access.redhat.com/ubi10/ubi

ENV TERM=xterm \
    APPLIANCE=true \
    RAILS_USE_MEMORY_STORE=true

# Force the sticky bit on /tmp - https://bugzilla.redhat.com/show_bug.cgi?id=2138434
RUN chmod +t /tmp

RUN --mount=type=bind,from=quay.io/manageiq/build_tools:el10,source=/tools,target=/usr/local/bin \
    ubi_2_stream_10 && \
    enable_epel && \
    dnf -y install https://rpm.manageiq.org/release/21-uhlmann/el10/noarch/manageiq-release-21.0-1.el10.noarch.rpm && \
    dnf -y --disablerepo=ubi-10-baseos-rpms swap openssl-fips-provider openssl-libs && \
    dnf -y update && \
    dnf -y group install "development tools" && \
    dnf config-manager --setopt=tsflags=nodocs --save && \
    dnf config-manager --setopt=epel.exclude=*qpid-proton* --save && \
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
      libyaml-devel \
      nodejs \
      npm \
      openssl-devel \
      platform-python-devel \
      # PostgreSQL 16 packages instead of postgresql-server
      postgresql-contrib \
      postgresql-server \
      qpid-proton-c-devel \
      rpm-build \
      ruby-devel \
      wget \
      which \
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
      python3.12-devel \
      python3.12-cryptography \
      python3.12-packaging \
      python3.12-pip \
      python3.12-pyyaml \
      python3.12-wheel && \
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

ENTRYPOINT ["/build_scripts/container-assets/user-entrypoint.sh"]
