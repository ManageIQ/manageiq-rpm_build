%global product_summary Ansible virtual environmnent for PRODUCT_SUMMARY
%global app_root VENV_ROOT
%global manifest_root /opt/ORG_NAME/manifest

Name:     PRODUCT_NAME
Version:  VERSION
Release:  1%{?dist}
Summary:  %{product_summary}
License:  Apache-2.0
URL:      https://github.com/ManageIQ/manageiq
Source0:  %{name}-%{version}.tar.gz
AutoReqProv: no

%description
%{product_summary}

%prep
%setup -q

%install
%{__mkdir} -p %{buildroot}%{app_root}
%{__cp} -r . %{buildroot}%{app_root}

%{__mkdir} -p %{buildroot}%{manifest_root}
%{__mv} %{buildroot}/%{app_root}/ansible_venv_manifest.csv %{buildroot}%{manifest_root}

ln -s ./lib %{buildroot}%{app_root}/venv/lib64
ln -s /usr/bin/python3.8 %{buildroot}%{app_root}/venv/bin/python3.8
ln -s ./python3.8 %{buildroot}%{app_root}/venv/bin/python3
ln -s ./python3 %{buildroot}%{app_root}/venv/bin/python

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{app_root}
%{manifest_root}/ansible_venv_manifest.csv

%changelog
* Wed Oct 7 2020 Satoe Imaishi <simaishi@redhat.com> - 1.0.0-1
- Initial build
