%global pgmajorversion 10
%global pgpackageversion %(echo %{pgmajorversion} | tr -d .)
%global sname repmgr
%if 0%{?rhel} && 0%{?rhel} <= 6
%global systemd_enabled 0
%else
%global systemd_enabled 1
%endif

%global extra_version %{nil}

%global _varrundir %{_localstatedir}/run/%{sname}

Name:        %{sname}%{pgpackageversion}
Version:    4.0.6
Release:    1%{nil}%{?dist}
Summary:    Replication Manager for PostgreSQL Clusters
License:    GPLv3+
URL:        https://www.repmgr.org
Source0:    http://repmgr.org/download/%{sname}-%{version}%{extra_version}.tar.bz2
Source1:    repmgr-pg%{pgpackageversion}.service
Source2:    repmgr-pg%{pgpackageversion}.init
Source3:    repmgr-pg%{pgpackageversion}.sysconfig
Patch0:     repmgr-pg%{pgpackageversion}-config-file-location.patch

%if %{systemd_enabled}
BuildRequires:  systemd
# We require this to be present for %%{_prefix}/lib/tmpfiles.d
Requires:        systemd
Requires(post):     systemd-sysv
Requires(post):     systemd
Requires(preun):    systemd
Requires(postun):   systemd
%else
Requires(post):     chkconfig
Requires(preun):    chkconfig
# This is for /sbin/service
Requires(preun):    initscripts
Requires(postun):   initscripts
# This is for older spec files (RHEL <= 6)
Group:        Applications/Databases
BuildRoot:        %{_tmppath}/%{name}-%{version}%{extra_version}-%{release}-root-%(%{__id_u} -n)
%endif
BuildRequires:    postgresql, postgresql-devel, postgresql-static
BuildRequires:    libxslt-devel, pam-devel, openssl-devel, readline-devel
Requires:         postgresql-server

%description
repmgr is an open-source tool suite for managing replication and failover in a
cluster of PostgreSQL servers. It enhances PostgreSQL's built-in hot-standby
capabilities with tools to set up standby servers, monitor replication, and
perform administrative tasks such as failover or manual switchover operations.

repmgr4 is a complete rewrite of the existing repmgr codebase and brings with
it many improvements and additional functionality.

If upgrading from repmgr3, please read the documentation carefully as there
are a number of changes, particularly in the configuration file and
command line option handling.

%prep
%setup -q -n %{sname}-%{version}%{extra_version}
%patch0 -p0

%build

PG_CONFIG=/usr/bin/pg_config ./configure

%{__make} PG_CONFIG=/usr/bin/pg_config USE_PGXS=1 %{?_smp_mflags}

%install
%{__mkdir} -p %{buildroot}/usr/bin/
%if %{systemd_enabled}
# Use new %%make_install macro:
USE_PGXS=1 %make_install  DESTDIR=%{buildroot}
%else
# Use older version
USE_PGXS=1 %{__make} install  DESTDIR=%{buildroot}
%endif
%{__mkdir} -p %{buildroot}/usr/bin/
%{__mkdir} -p %{buildroot}/%{_sysconfdir}/%{sname}/%{pgmajorversion}/

%if %{systemd_enabled}
install -d %{buildroot}%{_unitdir}
install -m 644 %{SOURCE1} %{buildroot}%{_unitdir}/%{name}.service

# ... and make a tmpfiles script to recreate it at reboot.
%{__mkdir} -p %{buildroot}%{_tmpfilesdir}
cat > %{buildroot}%{_tmpfilesdir}/%{name}.conf <<EOF
d %{_varrundir} 0755 postgres postgres -
EOF

%else
install -d %{buildroot}%{_sysconfdir}/init.d
install -m 755 %{SOURCE2}  %{buildroot}%{_sysconfdir}/init.d/%{sname}-%{pgpackageversion}
# Create the sysconfig directory and config file:
install -d -m 700 %{buildroot}%{_sysconfdir}/sysconfig/%{sname}/
install -m 600 %{SOURCE3} %{buildroot}%{_sysconfdir}/sysconfig/%{sname}/%{sname}-%{pgpackageversion}
%endif

%pre
if [ ! -x /var/log/repmgr ]
then
    %{__mkdir} -m 700 /var/log/repmgr
    %{__chown} -R postgres: /var/log/repmgr
fi

%post
/sbin/ldconfig
%if %{systemd_enabled}
%systemd_post %{sname}-%{pgpackageversion}.service
%tmpfiles_create
%else
# This adds the proper /etc/rc*.d links for the script
/sbin/chkconfig --add %{sname}-%{pgpackageversion}
%endif
if [ ! -x %{_varrundir} ]
then
    %{__mkdir} -m 700 %{_varrundir}
    %{__chown} -R postgres: %{_varrundir}
fi

%postun -p /sbin/ldconfig

%files
%if %{systemd_enabled}
%doc CREDITS HISTORY README.md
%license LICENSE
%else
%defattr(-,root,root,-)
%doc CREDITS HISTORY README.md LICENSE
%endif
%dir %{_sysconfdir}/%{sname}/%{pgmajorversion}/
/usr/bin/repmgr
/usr/bin/repmgrd
/usr/lib64/pgsql/repmgr.so
/usr/share/pgsql/extension/repmgr.control
/usr/share/pgsql/extension/repmgr--unpackaged--4.0.sql
/usr/share/pgsql/extension/repmgr--4.0.sql
%if %{systemd_enabled}
%ghost %{_varrundir}
%{_tmpfilesdir}/%{name}.conf
%attr (644, root, root) %{_unitdir}/%{name}.service
%else
%{_sysconfdir}/init.d/%{sname}-%{pgpackageversion}
%config(noreplace) %attr (600,root,root) %{_sysconfdir}/sysconfig/%{sname}/%{sname}-%{pgpackageversion}
%endif

%changelog
* Mon Jun 11 2018 - Giulio Calacoci <giulio.calacoci@2ndquadrant.it> 4.0.6-1
- Upstream release 4.0.6-1

* Tue May 1 2018 - Pallavi Sontakke <pallavi.sontakke@2ndquadrant.com> 4.0.5-1
- Upstream release 4.0.5-1

* Thu Mar 8 2018 - Marco Nenciarini <marco.nenciarini@2ndquadrant.it> 4.0.4-1
- Upstream release 4.0.4-1

* Wed Feb 14 2018 - Giulio Calacoci <giulio.calacoci@2ndquadrant.it> 4.0.3-1
- Upstream release 4.0.3-1

* Wed Jan 17 2018 - Giulio Calacoci <giulio.calacoci@2ndquadrant.it> 4.0.2-1
- Upstream release 4.0.2-1

* Mon Dec 11 2017 - Marco Nenciarini <marco.nenciarini@2ndquadrant.it> 4.0.1-1
- Upstream release 4.0.1-1

* Mon Nov 20 2017 - Giulio Calacoci <giulio.calacoci@2ndquadrant.it> 4.0.0-1
- Upstream release 4.0.0-1

* Tue Sep 10 2017 - Ian Barwick <ian@2ndquadrant.com> 4.0-0.1.beta1
- Upstream release 4.0-beta1
