%global appliance_root /opt/manageiq/manageiq-appliance
%global app_root /var/www/miq/vmdb
%global debug_package %{nil}

Name:     manageiq-appliance
Version:  RPM_VERSION
Release:  RPM_RELEASE%{?dist}
Summary:  ManageIQ Management Engine appliance configuration

Group:    Applications/Internet
License:  Unknown
URL:      https://github.com/ManageIQ/manageiq-appliance

Source0:  %{name}-%{version}.tar.gz

Requires: manageiq-appliance-common = %{version}

Requires: postgresql-server
Requires: repmgr10 >= 4.0.6

Requires: httpd
Requires: lvm2
Requires: memcached

# NTP
Requires: chrony

# External Authentication
Requires: sssd >= 1.11.6
Requires: sssd-dbus >= 1.11.6

# External Authentication - IPA
Requires: c-ares >= 1.7.0
Requires: ipa-admintools >= 3.0.0
Requires: ipa-client >= 3.0.0
Requires: mod_intercept_form_submit >= 0.9.7
Requires: mod_auth_gssapi
Requires: mod_authnz_pam >= 0.9.2
Requires: mod_lookup_identity >= 0.9.2
Requires: mod_ssl

# External Authentication - Active Directory
Requires: adcli
Requires: oddjob
Requires: oddjob-mkhomedir
Requires: realmd
Requires: samba-common
Requires: samba-common-tools

# External Authentication - SAML
Requires: mod_auth_mellon

# External Authentication - OpenID-Connect
# Requires: mod_auth_openidc

# SCAP
Requires: openscap
Requires: scap-security-guide

# Software Update
Requires: yum-utils

# Email
Requires: postfix

%description
ManageIQ Management Engine Appliance

%package common
Summary:  ManageIQ Management Engine appliance common
Requires: manageiq = %{version}
Requires: nmap-ncat
# For log rotate
Requires: cronie
Requires: logrotate
# External Authentication - LDAP
Requires: openldap-clients

%description common
ManageIQ Management Engine appliance common

%package tools
Summary:  ManageIQ Management Engine appliance tools
Requires: less
Requires: nano
Requires: smem
Requires: tree
Requires: unzip
Requires: vim-enhanced
Requires: wget

%description tools
ManageIQ Management Engine appliance tools

%prep
%setup -q

%pretrans -p <lua>
if posix.access('/bin/evmserver.sh', 'x') then
  local pid = posix.fork ()
  if ( pid == -1 ) then
    print ("The fork failed.")
  elseif ( pid == 0 ) then
    posix.exec('/bin/evmserver.sh', 'update_stop')
  else
    posix.wait(pid)
  end
end

%posttrans -p <lua>
if posix.access('/bin/evmserver.sh', 'x') then
  local pid = posix.fork ()
  if ( pid == -1 ) then
    print ("The fork failed.")
  elseif ( pid == 0 ) then
    posix.exec('/bin/evmserver.sh', 'update_start')
  else
    posix.wait(pid)
  end
end

%install

%{__mkdir} -p %{buildroot}%{appliance_root}
%{__cp} -r * %{buildroot}%{appliance_root}
%{__mkdir} -p %{buildroot}/etc/httpd/conf.d
%{__mkdir} -p %{buildroot}%{app_root}/log/apache

#symlink some executables
%{__mkdir} -p %{buildroot}/%{_bindir}
pushd ./LINK/usr/bin
  for filename in `ls`; do
    ln -s %{appliance_root}/LINK/usr/bin/$filename %{buildroot}/%{_bindir}/$filename
  done
popd

#symlink some configuration files
pushd ./LINK/etc
  for dirname in `ls`; do
    pushd ./$dirname
      %{__mkdir} -p %{buildroot}/%{_sysconfdir}/$dirname
      for filename in `ls`; do
        ln -s %{appliance_root}/LINK/etc/$dirname/$filename %{buildroot}/%{_sysconfdir}/$dirname/$filename
      done
    popd
  done
popd

%{__mkdir} -p %{buildroot}/root
pushd ./LINK/root
  ln -s %{appliance_root}/LINK/root/.ansible.cfg %{buildroot}/root/.ansible.cfg
  ln -s %{appliance_root}/LINK/root/.bowerrc %{buildroot}/root/.bowerrc
popd

pushd ./LINK
  ln -s %{appliance_root}/LINK/.toprc %{buildroot}/.toprc
popd

#copy all files/directories below COPY
%{__cp} -r ./COPY/* %{buildroot}/

%post
#motd is owned by system
%{__cp} -f %{_sysconfdir}/motd.manageiq %{_sysconfdir}/motd

systemctl daemon-reload

# Note, the last command from a scriplet sets the exit status
# for the scriplet so we can't one-line this.  We also want
# a failure in the restart to fail the scriplet/rpm install.
if systemctl is-active --quiet evm-failover-monitor; then
  systemctl restart evm-failover-monitor
fi

%post common
%post tools

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{_sysconfdir}/motd.manageiq

%files common
%defattr(-,root,root,-)
/.toprc
/root/.ansible.cfg
/root/.bowerrc
%{appliance_root}
%{app_root}/log/apache
%{_bindir}/cloud_ds_check.sh
%{_bindir}/cockpit-auth-miq
%{_bindir}/evm*
%{_bindir}/fix_auth
%{_bindir}/generate_miq_server_cert.sh
%{_bindir}/miq*
%{_bindir}/normalize_userid_to_upn
%{_bindir}/pg_inspector_server.sh
%{_prefix}/lib/systemd/system/cloud-ds-check.service
%{_prefix}/lib/systemd/system/evm*
%{_prefix}/lib/systemd/system/miq*
%{_sbindir}/ifup-local
%{_sysconfdir}/cloud/cloud.cfg.d/10_miq_*.cfg
%{_sysconfdir}/cron.hourly/miq*
%{_sysconfdir}/cron.hourly/pg-inpsector-server-hourly.cron
%{_sysconfdir}/default/evm*
%{_sysconfdir}/httpd/conf.d/manageiq-*
%{_sysconfdir}/issue.template
%{_sysconfdir}/logrotate.d/miq_logs.conf
%{_sysconfdir}/manageiq/postgresql.conf.d/01_miq_overrides.conf
%{_sysconfdir}/profile.d/evm.sh
%{_sysconfdir}/sudoers.d/repmgr

%files tools

%changelog
* Tue Apr 14 2020 Satoe Imaishi <simaishi@redhat.com> - 11.0.0-1
- 11.0.0-1 build
