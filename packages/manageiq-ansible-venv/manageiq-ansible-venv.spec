%global app_root /var/lib/manageiq
%global _python_bytecompile_extra 0

Name:     manageiq-ansible-venv
Version:  1.0.0
Release:  1%{?dist}
Summary:  ManageIQ Ansible Virtualenv
License:  Apache-2.0
URL:      https://github.com/ManageIQ/manageiq
Source0:  %{name}-%{version}.tar.gz
AutoReqProv: no

BuildRequires: /usr/bin/pathfix.py

%description
ManageIQ Ansible module virtual environmnent

%prep
%setup -q
pathfix.py -pni "%{__python3} %{py3_shbang_opts}" .

%install
%{__mkdir} -p %{buildroot}%{app_root}
%{__cp} -r . %{buildroot}%{app_root}

ln -s %{app_root}/venv/lib %{buildroot}%{app_root}/venv/lib64

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{app_root}

%changelog
* Wed Oct 7 2020 Satoe Imaishi <simaishi@redhat.com> - 1.0.0-1
- Initial build
