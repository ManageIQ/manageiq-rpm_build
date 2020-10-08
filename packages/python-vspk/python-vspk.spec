%global srcname vspk

# cli doesn't work with python3, ignore cli bytecompile error
# https://github.com/nuagenetworks/vspk-python/issues/38
%define _python_bytecompile_errors_terminate_build 0

Name:           python-%{srcname}
Version:        5.3.2
Release:        1%{?dist}
Summary:        SDK for the VSD API

License:        BSD-3-Clause
URL:            http://nuagenetworks.net/
Source0:        https://files.pythonhosted.org/packages/source/v/%{srcname}/%{srcname}-%{version}.tar.gz

BuildArch:      noarch

%global vspk_desc \
VSPK-PythonVSPK-Python is a Python SDK for Nuage VSP Platform

%description
%{vspk_desc}

%package -n python3-%{srcname}
Summary:  SDK for the VSD API
BuildRequires:  python3-devel
BuildRequires:  python3-setuptools
Requires: python3-bambou >= 2.0
Requires: python3-colorama
Requires: python3-tabulate

%description -n python3-%{srcname}
%{vspk_desc}

%prep
%autosetup -n %{srcname}-%{version}
# Remove bundled egg-info
rm -rf %{pypi_name}.egg-info

%build
%py3_build

%install
%py3_install

%files -n python3-%{srcname}
%license LICENSE
%doc README.md
%{_bindir}/vsd
%{_prefix}/vspk
%{python3_sitelib}/%{srcname}
%{python3_sitelib}/%{srcname}-%{version}-py?.?.egg-info

%changelog
* Thu Sep 24 2020 Satoe Imaishi <simaishi@redhat.com> - 5.3.2-1
- Initial Release for ManageIQ
