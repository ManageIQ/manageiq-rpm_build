%global srcname bambou

Name:           python-%{srcname}
Version:        3.1.1
Release:        1%{?dist}
Summary:        REST Library for Nuage Networks

License:        BSD-3-Clause
URL:            https://github.com/nuagenetworks/bambou
Source0:        https://files.pythonhosted.org/packages/source/b/%{srcname}/%{srcname}-%{version}.tar.gz
BuildArch:      noarch

BuildRequires:  python3-devel
BuildRequires:  python3-setuptools

%package -n     python3-%{srcname}
Summary:        REST Library for Nuage Networks

Requires:       python3-future
Requires:       python3-requests

%global bambou_desc \
Bambou is a Python ReST layer for Nuage Networks' APIs base concepts. It works\
on top of the requests library and provides an object oriented layer for\
manipulating ReST entities.Bambou can not be used as is, and it's mainly used by\
the Nuage Networks' vsdk and vspk.

%description
%{bambou_desc}

%description -n python3-%{srcname}
%{bambou_desc}

%prep
%autosetup -n %{srcname}-%{version}
# Remove bundled egg-info
rm -rf %{pypi_name}.egg-info

%build
%py3_build

%install
%py3_install

%files -n python3-%{srcname}
%doc README.md
%{python3_sitelib}/%{srcname}
%{python3_sitelib}/%{srcname}-%{version}-py?.?.egg-info

%changelog
* Thu Sep 24 2020 Satoe Imaishi <simaishi@redhat.com> - 3.1-1
- Initial Release for ManageIQ
