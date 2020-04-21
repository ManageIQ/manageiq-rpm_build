%global app_root /opt/manageiq/manageiq-gemset
%global __brp_mangle_shebangs_exclude_from /test/|/bundler/templates/Executable
%global debug_package %{nil}

Name:      manageiq-gemset
Version:   RPM_VERSION
Release:   RPM_RELEASE%{?dist}
Summary:   ManageIQ Management Engine Gemset
Group:     Applications/System
License:   "GPLv2+, Apache Public License 2.0, The MIT License and Ruby License"
URL:       https://github.com/ManageIQ/manageiq
Source0:   %{name}-%{version}.tar.gz

BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch: x86_64

BuildRequires: /usr/bin/pathfix.py

Requires: cifs-utils
Requires: nfs-utils
Requires: openscap-scanner
Requires: nodejs
Requires: wmi

# For Miq IPMI (gems-pending)
Requires: OpenIPMI
Requires: freeipmi
Requires: ipmitool

# For Nuage
Requires: cyrus-sasl
Requires: cyrus-sasl-plain

# For IMS
Requires: v2v-conversion-host-ansible

# For Appliance Console
Requires: network-scripts

%description
ManageIQ Management Engine Gemset

%prep
%setup -q
pathfix.py -pni "%{__python3} %{py3_shbang_opts}" .

%build
cat <<"EOF" > enable
export APPLIANCE="true"
export GEM_HOME=%{app_root}
export GEM_PATH=%{app_root}:$(gem env path)
export PATH=%{app_root}/bin:$PATH
EOF

%install
rm -rf $RPM_BUILD_ROOT

%{__mkdir} -p %{buildroot}%{app_root}
%{__cp} -r bin %{buildroot}%{app_root}
%{__cp} -r build_info %{buildroot}%{app_root}
%{__cp} -r bundler %{buildroot}%{app_root}
%{__cp} -r cache %{buildroot}%{app_root}
%{__cp} -r doc %{buildroot}%{app_root}
%{__cp} -r extensions %{buildroot}%{app_root}
%{__cp} -r gems %{buildroot}%{app_root}
%{__cp} -r specifications %{buildroot}%{app_root}
%{__cp} -r vmdb %{buildroot}%{app_root}
install -m644 enable %{buildroot}%{app_root}

# workaround
%{__rm} -rf %{buildroot}/%{app_root}/gems/ffi-*/ext

%posttrans
# 'bin' needs to be copied, not symlinked
[[ -e /var/www/miq/vmdb/bin ]] && rm -rf /var/www/miq/vmdb/bin
cp -r %{app_root}/vmdb/bin /var/www/miq/vmdb/bin

files=".bundle Gemfile.lock public/assets public/packs"
for file in ${files}
do
  [[ -e /var/www/miq/vmdb/${file} ]] && rm -rf /var/www/miq/vmdb/${file}
  ln -s %{app_root}/vmdb/${file} /var/www/miq/vmdb/${file}
done

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%dir %{app_root}
%{app_root}/bin
%{app_root}/build_info
%{app_root}/bundler
%{app_root}/cache
%{app_root}/doc
%{app_root}/extensions
%{app_root}/gems
%{app_root}/specifications
%{app_root}/vmdb
%{app_root}/enable

%changelog
* Thu Apr 16 2020 Satoe Imaishi <simaishi@redhat.com> - 11.0.0-1
- Initial Build
