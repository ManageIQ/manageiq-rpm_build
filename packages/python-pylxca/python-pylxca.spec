%global srcname pylxca

Name:           python-%{srcname}
Version:        2.1.1
Release:        1%{?dist}
Summary:        It is tool/api to connect LXCA from command line

License:        Apache-2.0
URL:            http://www.lenovo.com
Source0:        https://files.pythonhosted.org/packages/source/p/%{srcname}/%{srcname}-%{version}.tar.gz
BuildArch:      noarch

BuildRequires:  python3-devel
BuildRequires:  python3-setuptools

%global pylxca_desc \
PyLXCA is Python based interface for Lenovo xClarity Administration APIs.\
PyLXCA command-line interface (CLI) provides a Python-based\
library of commands to automate provisioning and resource management.The Lenovo\
XClarity Administrator PYLXCA CLI provide an interface to Lenovo XClarity\
Administrator REST APIs to automate functions.

%description
%{pylxca_desc}

%package -n     python3-%{srcname}
Summary:        It is tool/api to connect LXCA from command line

Requires:       python3-requests >= 2.7.0
Requires:       python3-requests-toolbelt >= 0.8.0
Requires:       python3-unittest2

%description -n python3-%{srcname}
%{pylxca_desc}

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
%{_bindir}/lxca_shell
%{python3_sitelib}/%{srcname}
%{python3_sitelib}/%{srcname}-%{version}-py?.?.egg-info

%changelog
* Thu Sep 24 2020 Satoe Imaishi <simaishi@redhat.com> - 2.1.1-1
- Initial Release for ManageIQ
