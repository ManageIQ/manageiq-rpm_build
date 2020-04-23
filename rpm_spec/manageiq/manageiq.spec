%global app_root /var/www/miq/vmdb
%global debug_package %{nil}

Name:     manageiq
Version:  RPM_VERSION
Release:  RPM_RELEASE%{?dist}
Summary:  ManageIQ Management Engine

Group:    Applications/System
License:  Unknown
URL:      https://github.com/ManageIQ/manageiq
Source0:  %{name}-%{version}.tar.gz

# Ruby
Requires: ruby

Requires: manageiq-gemset = %{version}

Requires: ansible
Requires: ansible-runner
Requires: cockpit
Requires: cockpit-ssh
Requires: cockpit-ws
Requires: insights-client
Requires: net-snmp
Requires: net-snmp-libs
Requires: net-snmp-utils
Requires: redhat-support-tool
Requires: socat

%description
ManageIQ Management Engine

%prep
%setup -q

%build

%pre

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

%{__mkdir} -p %{buildroot}%{app_root}
%{__cp} -r * %{buildroot}%{app_root}

%post
%{__cp} -f %{app_root}/config/cable.yml.sample %{app_root}/config/cable.yml

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{app_root}
%config(noreplace) %{app_root}/certs
%config(noreplace) %{app_root}/public/custom.css

%changelog
* Tue Apr 14 2020 Satoe Imaishi <simaishi@redhat.com> - 11.0.0-1
- 11.0.0-1 build
