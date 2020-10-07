Name:      manageiq-release
Version:   10.0
Release:   1%{dist}
Summary:   ManageIQ RPM repository configuration
License:   Apache-2.0
URL:       https://rpm.manageiq.org/release/
Source0:   RPM-GPG-KEY-MANAGEIQ
Source1:   manageiq-10-jansa.repo
BuildArch: noarch

%description
This package contains the ManageIQ repository GPG key as well as configuration for yum.

%prep
%setup -q -c -T
install -pm 644 %{SOURCE0} .

%build

%install
rm -rf $RPM_BUILD_ROOT

#GPG Key
install -Dpm 644 %{SOURCE0} $RPM_BUILD_ROOT%{_sysconfdir}/pki/rpm-gpg/RPM-GPG-KEY-MANAGEIQ

# yum
install -dm 755 $RPM_BUILD_ROOT%{_sysconfdir}/yum.repos.d
install -pm 644 %{SOURCE1} $RPM_BUILD_ROOT%{_sysconfdir}/yum.repos.d

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%config(noreplace) /etc/yum.repos.d/*
/etc/pki/rpm-gpg/*

%changelog
* Wed May 13 2020 Brandon Dunne <brandondunne@hotmail.com> - 10.0-1%{dist}
- Initial build of manageiq-release for Jansa.
