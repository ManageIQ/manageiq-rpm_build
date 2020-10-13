%global product_summary Ansible virtual environmnent for PRODUCT_SUMMARY

%global app_root VENV_ROOT
%global _python_bytecompile_extra 0

Name:     PRODUCT_NAME
Version:  VERSION
Release:  1%{?dist}
Summary:  %{product_summary}
License:  Apache-2.0
URL:      https://github.com/ManageIQ/manageiq
Source0:  %{name}-%{version}.tar.gz
AutoReqProv: no

BuildRequires: /usr/bin/pathfix.py

%description
%{product_summary}

%prep
%setup -q
pathfix.py -pni "%{__python3} %{py3_shbang_opts}" .

%install
%{__mkdir} -p %{buildroot}%{app_root}
%{__cp} -r . %{buildroot}%{app_root}

ln -s %{app_root}/venv/lib %{buildroot}%{app_root}/venv/lib64
ln -s %{__python3} %{buildroot}%{app_root}/venv/bin/python3
ln -s %{app_root}/venv/bin/python3 %{buildroot}%{app_root}/venv/bin/python

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{app_root}

%changelog
* Wed Oct 7 2020 Satoe Imaishi <simaishi@redhat.com> - 1.0.0-1
- Initial build
