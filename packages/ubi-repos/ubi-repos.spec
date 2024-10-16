Name:           ubi-repos
Version:        8
Release:        1%{?dist}
Summary:        UBI package repositories
License:        UBI-EULA
URL:            https://developers.redhat.com/articles/ubi-faq
BuildArch:      noarch

Source1:        EULA_Red_Hat_Universal_Base_Image_English_20190422.pdf
Source101:      ISV-Container-signing-key
Source102:      RPM-GPG-KEY-redhat-beta
Source103:      RPM-GPG-KEY-redhat-release
SOURCE104:      ubi.repo

Requires:       system-release(releasever) = %{version}
Requires:       ubi-gpg-keys = %{version}-%{release}
Provides:       ubi-repos(%{version})

%description
This package provides the package repository files for UBI.

%package -n ubi-gpg-keys
Summary:        UBI RPM signing keys

%description -n ubi-gpg-keys
This package provides the RPM signature keys for UBI.

%install
# copy license here for %%license macro
cp %{SOURCE1} .

# copy GPG keys
install -d -m 0755 %{buildroot}%{_sysconfdir}/pki/rpm-gpg
install -p -m 0644 %{_sourcedir}/ISV-Container-signing-key %{buildroot}%{_sysconfdir}/pki/rpm-gpg/
install -p -m 0644 %{_sourcedir}/RPM-GPG-KEY-* %{buildroot}%{_sysconfdir}/pki/rpm-gpg/

# copy yum repos
install -d -m 0755 %{buildroot}%{_sysconfdir}/yum.repos.d
install -p -m 0644 %{_sourcedir}/*.repo %{buildroot}%{_sysconfdir}/yum.repos.d/

%files -n ubi-gpg-keys
%{_sysconfdir}/pki/rpm-gpg/

%files -n ubi-repos
%license EULA_Red_Hat_Universal_Base_Image_English_20190422.pdf
%dir %{_sysconfdir}/yum.repos.d
%config(noreplace) %{_sysconfdir}/yum.repos.d/ubi.repo

%changelog
* Wed Oct 16 2024 Brandon Dunne <brandondunne@hotmail.com> - 8-1
- Initial commit
